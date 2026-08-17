# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "open3"
require "rbconfig"
require "socket"
require "qa_chain_contract"
require_relative "../full/reference/qa_chain_server"

class QaChainContractTest < Minitest::Test
  SCRIPT = File.join(ROOT, "full/scripts/agent-task")

  def test_client_default_injects_qa_for_coder_and_product
    %w[coder product].each do |role|
      payload = AgentArchitectKit::QaChainContract.build_client_payload(
        role: role,
        subject: "Ship feature",
        task_type: "feature",
        priority: "P1",
        origin: "internal"
      )

      assert_equal "qa", payload.fetch(:next_tasks).first.fetch("role"), role
    end
  end

  def test_cli_refuses_reasonless_gated_opt_out_before_an_api_call
    %w[coder product].each do |role|
      output, status = Open3.capture2e(
        RbConfig.ruby,
        SCRIPT,
        "add", role, "Skip QA", "--no-chain",
        chdir: ROOT
      )

      refute_predicate status, :success?, role
      assert_includes output, "--no-chain-reason", role
      refute_includes output, "Created task", role
    end
  end

  def test_cli_forwards_justified_opt_out_and_surfaces_the_reason
    reason = "Documentation-only migration with no executable change"
    request, output, status = capture_create_request(
      "coder", "Commit docs", "--no-chain", "--no-chain-reason", reason
    )

    assert_predicate status, :success?
    assert_equal true, request.fetch("no_chain")
    assert_equal reason, request.fetch("no_chain_reason")
    assert_includes output, reason
    assert_includes output, "persisted for server audit"
  end

  def test_cli_default_payload_contains_a_qa_child
    request, _output, status = capture_create_request("coder", "Implement feature")

    assert_predicate status, :success?
    assert_equal "qa", request.fetch("next_tasks").first.fetch("role")
    refute request.key?("no_chain")
  end

  def test_server_persists_justified_opt_out_and_does_not_spawn_qa
    server = AgentArchitectKit::ReferenceQaChainServer.new
    task = server.create(
      role: "product",
      subject: "Metadata-only correction",
      no_chain: true,
      no_chain_reason: "No artifact or executable behavior changed"
    )
    server.complete(task["task_id"])

    assert_equal [], task["next_tasks"]
    assert_includes task["notes"], AgentArchitectKit::QaChainContract::NOTE_PREFIX
    assert_empty server.children_of(task["task_id"])
  end

  def test_server_rejects_an_explicit_empty_chain_without_reason
    [ [], "[]" ].each do |empty_chain|
      error = assert_raises(AgentArchitectKit::QaChainContract::RejectedOptOut) do
        AgentArchitectKit::QaChainContract.normalize_server_create(
          role: "coder", subject: "Raw bypass", next_tasks: empty_chain
        )
      end
      assert_includes error.message, "requires --no-chain-reason"
    end
  end

  def test_completion_fallback_is_idempotent_and_preserves_untrusted_origin
    server = AgentArchitectKit::ReferenceQaChainServer.new
    parent = server.import(
      task_id: "WQ-RAW",
      role: "coder",
      subject: "Task created outside the client",
      origin: "untrusted",
      status: "in_progress"
    )

    server.complete(parent["task_id"])
    server.complete(parent["task_id"])
    children = server.children_of(parent["task_id"])

    assert_equal 1, children.length
    assert_equal "qa", children.first["role"]
    assert_equal "untrusted", children.first["origin"]
    assert_equal "pending", children.first["status"]
  end

  def test_declared_default_chain_and_repeated_completion_create_only_one_qa_child
    server = AgentArchitectKit::ReferenceQaChainServer.new
    parent = server.create(
      role: "product",
      subject: "Launch customer artifact",
      priority: "P1",
      origin: "internal"
    )

    server.complete(parent["task_id"])
    server.complete(parent["task_id"])
    children = server.children_of(parent["task_id"])

    assert_equal 1, children.length
    assert_equal "qa", children.first["role"]
    assert_equal "ready", children.first["status"]
    assert_equal "internal", children.first["origin"]
  end

  private

  def capture_create_request(*arguments)
    server = TCPServer.new("127.0.0.1", 0)
    request_body = Queue.new
    responder = Thread.new do
      socket = server.accept
      headers = {}
      request_line = socket.gets
      while (line = socket.gets)
        break if line == "\r\n"
        key, value = line.split(":", 2)
        headers[key.downcase] = value.to_s.strip
      end
      body = socket.read(Integer(headers.fetch("content-length", "0")))
      request_body << JSON.parse(body)
      response = JSON.generate("task_id" => "WQ-TEST")
      socket.write(
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
        "Content-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}"
      )
      socket.close
      request_line
    ensure
      server.close
    end

    env = {
      "ORCHESTRATOR_API_URL" => "http://127.0.0.1:#{server.addr[1]}",
      "ORCHESTRATOR_API_PREFIX" => "/test",
      "ORCHESTRATOR_API_TOKEN" => "test-token",
      "AGENT_ROLE" => "coder"
    }
    output, status = Open3.capture2e(env, RbConfig.ruby, SCRIPT, "add", *arguments, chdir: ROOT)
    unless responder.join(2)
      responder.kill
      flunk "CLI did not reach the fake API: #{output}"
    end
    [ request_body.pop(true), output, status ]
  ensure
    server&.close unless server&.closed?
  end
end
