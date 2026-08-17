# frozen_string_literal: true

require_relative "test_helper"
require "harness_adapter"

class CodexScaffoldTest < Minitest::Test
  SCAFFOLD = File.join(ROOT, "core/codex")
  EXPECTED_ROLES = %w[coder designer marketing operations product qa].freeze

  def test_scaffold_uses_codex_project_instruction_and_custom_agent_conventions
    assert File.file?(File.join(SCAFFOLD, "AGENTS.md"))
    assert File.file?(File.join(SCAFFOLD, ".codex/config.toml"))

    roles = Dir[File.join(SCAFFOLD, ".codex/agents/*.toml")].map do |path|
      File.basename(path, ".toml")
    end.sort
    assert_equal EXPECTED_ROLES, roles
  end

  def test_role_files_have_required_fields_without_claude_frontmatter_or_model_pins
    EXPECTED_ROLES.each do |role|
      source = File.read(File.join(SCAFFOLD, ".codex/agents/#{role}.toml"))

      assert_match(/^name = "#{role}"$/, source, role)
      assert_match(/^description = ".+"$/, source, role)
      assert_match(/^developer_instructions = """$/, source, role)
      refute_match(/^---$/, source, role)
      refute_includes source, "@.claude/", role
      refute_match(/^tools:/, source, role)
      refute_match(/^model\s*=/, source, role)
    end
  end

  def test_every_shipped_role_passes_worker_preflight
    EXPECTED_ROLES.each do |role|
      adapter = AgentArchitectKit::HarnessAdapter.build(
        name: "codex",
        role: role,
        project_dir: SCAFFOLD,
        env: {
          "PATH" => ENV.fetch("PATH", ""),
          "CODEX_BIN" => File.join(ROOT, "test/fixtures/fake_harness")
        }
      )

      assert_same adapter, adapter.validate!, role
    end
  end
end
