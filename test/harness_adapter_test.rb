# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"
require "json"
require "socket"
require "tmpdir"
require "yaml"
require "harness_adapter"
load File.join(ROOT, "full/scripts/agent-worker")

class HarnessAdapterTest < Minitest::Test
  FAKE_HARNESS = File.join(ROOT, "test/fixtures/fake_harness")

  def setup
    @root = Dir.mktmpdir("agent-architect-harness")
    FileUtils.mkdir_p(File.join(@root, ".claude/agents"))
    File.write(File.join(@root, ".claude/agents/coder.md"), <<~MARKDOWN)
      ---
      name: coder
      description: Test coder
      ---
      Complete the task.
    MARKDOWN
    FileUtils.mkdir_p(File.join(@root, ".codex/agents"))
    File.write(File.join(@root, "AGENTS.md"), "# Test project instructions\n")
    File.write(File.join(@root, ".codex/config.toml"), "[agents]\nenabled = true\n")
    File.write(File.join(@root, ".codex/agents/coder.toml"), <<~TOML)
      name = "coder"
      description = "Test coder"
      developer_instructions = """
      Complete the assigned engineering task and report an explicit completion signal.
      """
    TOML
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_claude_command_is_an_argument_array_without_prompt_text_or_bypass_default
    adapter = build_adapter("claude")
    command = adapter.command

    assert_equal FAKE_HARNESS, command.first
    assert_equal [ "--print", "--agent", "coder", "--no-session-persistence", "--verbose" ], command.drop(1)
    refute_includes command, "--dangerously-skip-permissions"
    refute command.any? { |argument| argument.include?("private task body") }
  end

  def test_codex_command_uses_noninteractive_stdin_and_workspace_sandbox
    command = build_adapter("codex").command

    assert_equal [ FAKE_HARNESS, "exec", "--strict-config", "--ephemeral" ], command.first(4)
    assert_equal "workspace-write", command[command.index("--sandbox") + 1]
    assert_equal "-", command.last
    refute_includes command, "--dangerously-bypass-approvals-and-sandbox"
  end

  def test_runner_delivers_context_through_protected_stdin_file
    capture = File.join(@root, "prompt.txt")
    env = adapter_env("codex").merge("FAKE_PROMPT_FILE" => capture)
    adapter = AgentArchitectKit::HarnessAdapter.build(
      name: "codex", role: "coder", project_dir: @root, env: env
    )

    result = AgentArchitectKit::HarnessRunner.new(timeout_seconds: 2).run(
      adapter: adapter,
      context: "private task body"
    )

    assert_predicate result.status, :success?
    assert_includes File.read(capture), "private task body"
    refute_includes File.read(capture), "Complete the assigned engineering task"
    assert adapter.command.any? { |argument| argument.start_with?("developer_instructions=") }
    refute adapter.command.any? { |argument| argument.include?("private task body") }
  end

  def test_validation_fails_closed_for_missing_binary_and_role_configuration
    missing_binary = AgentArchitectKit::HarnessAdapter.build(
      name: "codex",
      role: "coder",
      project_dir: @root,
      env: adapter_env("codex").merge("CODEX_BIN" => "definitely-not-a-real-binary")
    )
    error = assert_raises(AgentArchitectKit::HarnessConfigurationError) { missing_binary.validate! }
    assert_includes error.message, "CODEX_BIN"

    FileUtils.rm_f(File.join(@root, ".codex/agents/coder.toml"))
    missing_role = build_adapter("codex")
    error = assert_raises(AgentArchitectKit::HarnessConfigurationError) { missing_role.validate! }
    assert_includes error.message, "custom agent definition"
  end

  def test_codex_runtime_preflight_loads_strict_config_without_a_model_request
    argv_file = File.join(@root, "preflight-argv.json")
    env = adapter_env("codex").merge("FAKE_ARGV_FILE" => argv_file)
    adapter = AgentArchitectKit::HarnessAdapter.build(
      name: "codex", role: "coder", project_dir: @root, env: env
    )

    assert_same adapter, adapter.validate_runtime!
    argv = JSON.parse(File.read(argv_file))
    assert_includes argv, "--strict-config"
    assert_includes argv, %(model_provider="#{AgentArchitectKit::CodexHarnessAdapter::PREFLIGHT_PROVIDER}")
    assert_equal "-", argv.last
  end

  def test_orchestrator_preflights_before_the_claim_request
    source = File.read(File.join(ROOT, "full/scripts/agent-orchestrator"))

    assert_operator source.index(".validate_runtime!"), :<, source.index('/claim")')
  end

  def test_completion_output_is_normalized_for_both_harnesses
    success = Struct.new(:success?, :exitstatus).new(true, 0)

    assert_equal "completed", AgentArchitectKit::CompletionContract.normalize(
      "work\nTASK_COMPLETE: verified\n", status: success
    )[:result]
    assert_equal "needs_review", AgentArchitectKit::CompletionContract.normalize(
      "NEEDS_REVIEW: inspect deployment\n", status: success
    )[:result]
    assert_equal "blocked", AgentArchitectKit::CompletionContract.normalize(
      "BLOCKED: missing authority\n", status: success
    )[:result]
    assert_equal "needs_review", AgentArchitectKit::CompletionContract.normalize(
      "ordinary final message\n", status: success
    )[:result]
  end

  def test_timeout_terminates_the_harness_process_group
    pid_file = File.join(@root, "pid")
    env = adapter_env("claude").merge(
      "FAKE_PID_FILE" => pid_file,
      "FAKE_SLEEP_SECONDS" => "5"
    )
    adapter = AgentArchitectKit::HarnessAdapter.build(
      name: "claude", role: "coder", project_dir: @root, env: env
    )

    result = AgentArchitectKit::HarnessRunner.new(
      timeout_seconds: 0.2,
      kill_grace_seconds: 0.1
    ).run(adapter: adapter, context: "timeout test")

    assert result.timed_out
    pid = Integer(File.read(pid_file))
    assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
  end

  def test_failed_harness_cannot_complete_a_task
    failure = Struct.new(:success?, :exitstatus).new(false, 7)

    result = AgentArchitectKit::CompletionContract.normalize(
      "TASK_COMPLETE: claimed success\n", status: failure
    )

    assert_equal "failed", result[:result]
    assert_includes result[:notes], "7"
  end

  def test_only_the_last_nonblank_line_can_report_completion
    success = Struct.new(:success?, :exitstatus).new(true, 0)
    [
      "TASK_COMPLETE: earlier claim\nActually, verification failed.\n",
      "```text\nTASK_COMPLETE: example\n```\n",
      "```text\nTASK_COMPLETE: unclosed example\n",
      "~~~~text\nTASK_COMPLETE: example\n~~~\nTASK_COMPLETE: still fenced\n",
      "    TASK_COMPLETE: indented code example\n",
      "> TASK_COMPLETE: quoted claim\n",
      "TASK_COMPLETE:   \n"
    ].each do |output|
      assert_equal "needs_review", AgentArchitectKit::CompletionContract.normalize(
        output, status: success
      )[:result], output.inspect
    end

    assert_equal "completed", AgentArchitectKit::CompletionContract.normalize(
      "```text\nexample\n```\nTASK_COMPLETE: verified\n\n", status: success
    )[:result]
  end

  def test_both_harnesses_fail_even_when_they_print_a_success_marker
    %w[claude codex].each do |name|
      adapter = AgentArchitectKit::HarnessAdapter.build(
        name: name, role: "coder", project_dir: @root,
        env: adapter_env(name).merge(
          "FAKE_OUTPUT" => "TASK_COMPLETE: claimed success",
          "FAKE_EXIT_STATUS" => "7"
        )
      )
      execution = AgentArchitectKit::HarnessRunner.new(
        timeout_seconds: 5, kill_grace_seconds: 0.1
      ).run(adapter: adapter, context: "failure regression")

      assert_equal 7, execution.status.exitstatus
      assert_equal "failed", AgentArchitectKit::CompletionContract.normalize(
        execution.output, status: execution.status, timed_out: execution.timed_out
      )[:result]
    end
  end

  def test_heartbeat_stops_without_leaving_a_thread
    writes = 0
    heartbeat = AgentArchitectKit::Heartbeat.new(interval: 0.01) { writes += 1 }.start
    sleep 0.04
    heartbeat.stop
    stopped_at = writes
    sleep 0.03

    refute heartbeat.alive?
    assert_equal stopped_at, writes
    assert_operator writes, :>=, 2
  end

  def test_worker_runs_fake_harness_reports_completion_and_does_not_log_task_body
    state_file = File.join(@root, "worker.running")
    completion_file = File.join(@root, "worker.complete")
    server, requests, responder = start_worker_api
    env = adapter_env("claude").merge(
      "AGENT_TASK_ID" => "WQ-TEST",
      "AGENT_ROLE" => "coder",
      "AGENT_PROJECT_DIR" => ROOT,
      "AGENT_CLAUDE_ROLE_DIR" => "core/agents",
      "AGENT_STATE_FILE" => state_file,
      "AGENT_COMPLETION_FILE" => completion_file,
      "ORCHESTRATOR_API_URL" => "http://127.0.0.1:#{server.addr[1]}",
      "ORCHESTRATOR_API_PREFIX" => "/test",
      "ORCHESTRATOR_API_TOKEN" => "test-token",
      "FAKE_OUTPUT" => "TASK_COMPLETE: fake worker verified"
    )

    exit_code = nil
    output, = capture_io { exit_code = AgentArchitectKit::AgentWorker.new(env: env).run }
    responder.join(2)
    completion = YAML.safe_load(File.read(completion_file))

    assert_equal 0, exit_code
    assert_equal "completed", completion.fetch("result")
    assert_includes requests.map { |request| request[1] }, "/test/orchestrator/api/tasks/WQ-TEST/in_progress"
    assert_includes requests.map { |request| request[1] }, "/test/orchestrator/api/tasks/WQ-TEST/complete"
    refute_includes output, "Sensitive subject must stay off logs"
    assert_includes output, "Completion=completed"
  ensure
    server&.close unless server&.closed?
    responder&.kill if responder&.alive?
  end

  private

  def adapter_env(name)
    {
      "PATH" => ENV.fetch("PATH", ""),
      "CLAUDE_BIN" => FAKE_HARNESS,
      "CODEX_BIN" => FAKE_HARNESS,
      "AGENT_HARNESS" => name
    }
  end

  def build_adapter(name)
    AgentArchitectKit::HarnessAdapter.build(
      name: name,
      role: "coder",
      project_dir: @root,
      env: adapter_env(name)
    )
  end

  def start_worker_api
    server = TCPServer.new("127.0.0.1", 0)
    requests = []
    responder = Thread.new do
      loop do
        socket = server.accept
        request_line = socket.gets.to_s
        method, path = request_line.split(" ", 3)
        headers = {}
        while (line = socket.gets)
          break if line == "\r\n"
          key, value = line.split(":", 2)
          headers[key.to_s.downcase] = value.to_s.strip
        end
        body = socket.read(Integer(headers.fetch("content-length", "0")))
        requests << [ method, path, body ]
        response_body = if method == "GET"
          JSON.generate(
            "task" => {
              "task_id" => "WQ-TEST",
              "role" => "coder",
              "subject" => "Sensitive subject must stay off logs",
              "task_type" => "feature",
              "priority" => "P1"
            }
          )
        else
          JSON.generate("status" => "ok")
        end
        socket.write(
          "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
          "Content-Length: #{response_body.bytesize}\r\nConnection: close\r\n\r\n#{response_body}"
        )
        socket.close
        break if path.end_with?("/complete")
      end
    ensure
      server.close unless server.closed?
    end
    [ server, requests, responder ]
  end
end
