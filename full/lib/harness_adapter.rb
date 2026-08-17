# frozen_string_literal: true

require "tempfile"
require "open3"
require "yaml"

module AgentArchitectKit
  class HarnessConfigurationError < StandardError; end

  HarnessRunResult = Struct.new(:output, :status, :timed_out, keyword_init: true)

  class HarnessAdapter
    SUPPORTED = %w[claude codex].freeze

    attr_reader :project_dir, :role

    def self.build(name:, role:, project_dir:, env: ENV)
      normalized = name.to_s.strip.downcase
      case normalized
      when "claude" then ClaudeHarnessAdapter.new(role: role, project_dir: project_dir, env: env)
      when "codex" then CodexHarnessAdapter.new(role: role, project_dir: project_dir, env: env)
      else
        raise HarnessConfigurationError,
          "Unsupported AGENT_HARNESS=#{name.inspect}; expected one of: #{SUPPORTED.join(', ')}"
      end
    end

    def initialize(role:, project_dir:, env: ENV)
      @role = role.to_s.strip
      @project_dir = File.expand_path(project_dir)
      @env = env
    end

    def validate!
      raise HarnessConfigurationError, "AGENT_ROLE is required" if role.empty?
      raise HarnessConfigurationError, "Project directory not found: #{project_dir}" unless Dir.exist?(project_dir)

      executable_path
      validate_role_configuration!
      self
    end

    def validate_runtime!
      validate!
      _output, status = Open3.capture2e(child_environment, executable_path, "--version", chdir: project_dir)
      unless status.success?
        raise HarnessConfigurationError,
          "#{harness_name} executable failed --version (exit #{status.exitstatus.inspect}): #{executable_path}"
      end
      self
    end

    def executable_path
      @executable_path ||= resolve_executable(configured_executable)
    end

    def child_environment
      @env.to_h
    end

    def decorate_context(context)
      context
    end

    private

    def resolve_executable(name)
      candidate = name.to_s.strip
      raise HarnessConfigurationError, "#{executable_env_key} is empty" if candidate.empty?

      path = if candidate.include?(File::SEPARATOR)
        File.expand_path(candidate, project_dir)
      else
        search_path(candidate)
      end

      unless path && File.file?(path) && File.executable?(path)
        raise HarnessConfigurationError,
          "#{harness_name} executable not found or not executable: #{candidate.inspect} " \
          "(set #{executable_env_key} or update PATH)"
      end

      path
    end

    def search_path(name)
      @env.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        candidate = File.join(directory, name)
        return candidate if File.file?(candidate) && File.executable?(candidate)
      end
      nil
    end

    def configured_executable
      @env.fetch(executable_env_key, default_executable)
    end

    def require_nonempty_file!(path, description)
      return path if File.file?(path) && !File.read(path, encoding: "UTF-8").strip.empty?

      raise HarnessConfigurationError, "Missing or empty #{description}: #{path}"
    end
  end

  class ClaudeHarnessAdapter < HarnessAdapter
    PERMISSION_MODES = %w[default acceptEdits auto dontAsk manual plan bypassPermissions].freeze

    def harness_name
      "Claude Code"
    end

    def executable_env_key
      "CLAUDE_BIN"
    end

    def default_executable
      "claude"
    end

    def command
      validate!
      args = [ executable_path, "--print", "--agent", role, "--no-session-persistence", "--verbose" ]
      mode = @env.fetch("AGENT_CLAUDE_PERMISSION_MODE", "default").to_s
      args.concat([ "--permission-mode", mode ]) unless mode == "default"
      args
    end

    def child_environment
      super.merge("CLAUDECODE" => nil)
    end

    private

    def validate_role_configuration!
      mode = @env.fetch("AGENT_CLAUDE_PERMISSION_MODE", "default").to_s
      unless PERMISSION_MODES.include?(mode)
        raise HarnessConfigurationError,
          "Invalid AGENT_CLAUDE_PERMISSION_MODE=#{mode.inspect}; expected one of: #{PERMISSION_MODES.join(', ')}"
      end

      path = File.join(project_dir, @env.fetch("AGENT_CLAUDE_ROLE_DIR", ".claude/agents"), "#{role}.md")
      source = File.read(require_nonempty_file!(path, "Claude agent definition"), encoding: "UTF-8")
      frontmatter = source.match(/\A---\s*\n(?<yaml>.*?)\n---\s*\n/m)
      raise HarnessConfigurationError, "Claude agent definition has no YAML frontmatter: #{path}" unless frontmatter

      metadata = YAML.safe_load(frontmatter[:yaml]) || {}
      unless metadata["name"].to_s == role
        raise HarnessConfigurationError,
          "Claude agent definition name mismatch in #{path}: expected #{role.inspect}"
      end
    rescue Psych::SyntaxError => e
      raise HarnessConfigurationError, "Invalid YAML frontmatter in #{path}: #{e.message}"
    end
  end

  class CodexHarnessAdapter < HarnessAdapter
    SANDBOX_MODES = %w[read-only workspace-write danger-full-access].freeze
    PREFLIGHT_PROVIDER = "agent-architect-kit-preflight-missing"

    def harness_name
      "Codex CLI"
    end

    def executable_env_key
      "CODEX_BIN"
    end

    def default_executable
      "codex"
    end

    def command
      validate!
      [
        executable_path,
        "exec",
        "--strict-config",
        "--ephemeral",
        "--sandbox", sandbox_mode,
        "--config", 'approval_policy="never"',
        "--config", "developer_instructions=#{developer_instructions.dump}",
        "--cd", project_dir,
        "-"
      ]
    end

    def child_environment
      super.merge("CODEX_THREAD_ID" => nil)
    end

    def decorate_context(context)
      context
    end

    # Force Codex to load strict project/user configuration, then stop locally
    # at a deliberately missing provider before any model request. A successful
    # fake harness is also accepted so the product suite stays hermetic.
    def validate_runtime!
      validate!
      command = [
        executable_path,
        "exec",
        "--strict-config",
        "--ephemeral",
        "--sandbox", "read-only",
        "--config", %(model_provider="#{PREFLIGHT_PROVIDER}"),
        "--config", "developer_instructions=#{developer_instructions.dump}",
        "--cd", project_dir,
        "-"
      ]
      output, status = Open3.capture2e(
        child_environment,
        *command,
        stdin_data: "Configuration preflight only.\n",
        chdir: project_dir
      )
      return self if status.success? || output.include?("Model provider `#{PREFLIGHT_PROVIDER}` not found")

      raise HarnessConfigurationError,
        "Codex CLI rejected configuration for role #{role.inspect} under #{project_dir} " \
        "(exit #{status.exitstatus.inspect}); inspect .codex/config.toml and #{role_path}"
    end

    private

    def sandbox_mode
      @env.fetch("AGENT_CODEX_SANDBOX", "workspace-write").to_s
    end

    def role_path
      File.join(project_dir, @env.fetch("AGENT_CODEX_ROLE_DIR", ".codex/agents"), "#{role}.toml")
    end

    def validate_role_configuration!
      unless SANDBOX_MODES.include?(sandbox_mode)
        raise HarnessConfigurationError,
          "Invalid AGENT_CODEX_SANDBOX=#{sandbox_mode.inspect}; expected one of: #{SANDBOX_MODES.join(', ')}"
      end

      require_nonempty_file!(File.join(project_dir, "AGENTS.md"), "Codex project instructions")
      require_nonempty_file!(File.join(project_dir, ".codex/config.toml"), "Codex project config")
      source = File.read(require_nonempty_file!(role_path, "Codex custom agent definition"), encoding: "UTF-8")

      configured_name = source[/^name\s*=\s*"([^"]+)"\s*$/, 1]
      unless configured_name == role
        raise HarnessConfigurationError,
          "Codex custom agent name mismatch in #{role_path}: expected #{role.inspect}"
      end
      unless source.match?(/^description\s*=\s*".+"\s*$/)
        raise HarnessConfigurationError, "Codex custom agent is missing description: #{role_path}"
      end
      developer_instructions
    end

    def developer_instructions
      @developer_instructions ||= begin
        source = File.read(role_path, encoding: "UTF-8")
        match = source.match(/^developer_instructions\s*=\s*"""\s*\n(?<body>.*?)\n"""\s*$/m)
        body = match && match[:body].to_s.strip
        if body.to_s.empty?
          raise HarnessConfigurationError,
            "Codex custom agent is missing multiline developer_instructions: #{role_path}"
        end
        body
      end
    end
  end

  class HarnessRunner
    def initialize(timeout_seconds: 3600, kill_grace_seconds: 5)
      @timeout_seconds = Float(timeout_seconds)
      @kill_grace_seconds = Float(kill_grace_seconds)
      raise ArgumentError, "timeout_seconds must be positive" unless @timeout_seconds.positive?
      raise ArgumentError, "kill_grace_seconds must be non-negative" if @kill_grace_seconds.negative?
    end

    def run(adapter:, context:)
      adapter.validate!
      Tempfile.create([ "agent-context", ".txt" ], adapter.project_dir) do |prompt_file|
        prompt_file.chmod(0o600)
        prompt_file.write(adapter.decorate_context(context))
        prompt_file.flush
        prompt_file.rewind

        output_reader, output_writer = IO.pipe
        pid = Process.spawn(
          adapter.child_environment,
          *adapter.command,
          in: prompt_file,
          out: output_writer,
          err: output_writer,
          chdir: adapter.project_dir,
          pgroup: true
        )
        output_writer.close

        output_thread = Thread.new { output_reader.read }
        wait_thread = Thread.new { Process.wait2(pid).last }
        timed_out = wait_thread.join(@timeout_seconds).nil?
        terminate_process_group(pid, wait_thread) if timed_out

        wait_thread.join
        output_thread.join
        HarnessRunResult.new(output: output_thread.value, status: wait_thread.value, timed_out: timed_out)
      ensure
        output_writer&.close unless output_writer&.closed?
        output_reader&.close unless output_reader&.closed?
      end
    end

    private

    def terminate_process_group(pid, wait_thread)
      kill_process_group("TERM", pid)
      return if wait_thread.join(@kill_grace_seconds)

      kill_process_group("KILL", pid)
    end

    def kill_process_group(signal, pid)
      Process.kill(signal, -pid)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end
  end
end
