# frozen_string_literal: true

require "json"

module AgentArchitectKit
  module QaChainContract
    GATED_ROLES = %w[coder product].freeze
    NOTE_PREFIX = "NO-CHAIN OPT-OUT"

    class RejectedOptOut < ArgumentError; end

    module_function

    def gated_role?(role)
      GATED_ROLES.include?(role.to_s.strip.downcase)
    end

    def default_chain(role:, subject:, priority: "P1")
      return nil unless gated_role?(role)

      [ {
        "role" => "qa",
        "subject" => "QA Review: #{subject}"[0, 121],
        "priority" => priority
      } ]
    end

    def build_client_payload(role:, subject:, task_type:, priority:, origin:, no_chain: false,
                             no_chain_reason: nil)
      normalized_role = role.to_s.strip.downcase
      reason = no_chain_reason.to_s.strip
      validate_opt_out!(role: normalized_role, no_chain: no_chain, reason: reason)

      payload = {
        role: normalized_role,
        subject: subject,
        task_type: task_type,
        priority: priority,
        origin: origin,
        next_tasks: no_chain ? nil : default_chain(role: normalized_role, subject: subject, priority: priority)
      }
      if no_chain
        payload[:no_chain] = true
        payload[:no_chain_reason] = reason unless reason.empty?
      end
      payload
    end

    def normalize_server_create(attributes)
      task = stringify_keys(attributes)
      role = task.fetch("role", "coder").to_s.strip.downcase
      reason = task["no_chain_reason"].to_s.strip
      explicit_empty = empty_chain?(task["next_tasks"])
      no_chain = truthy?(task["no_chain"]) || explicit_empty
      validate_opt_out!(role: role, no_chain: no_chain, reason: reason)

      task["role"] = role
      task["origin"] = normalized_origin(task["origin"])
      if no_chain
        task["next_tasks"] = []
        task["no_chain"] = true
        task["no_chain_reason"] = reason
        task["notes"] = append_opt_out_note(task["notes"], role: role, reason: reason)
      elsif task["next_tasks"].nil?
        task["next_tasks"] = default_chain(
          role: role,
          subject: task["subject"],
          priority: task.fetch("priority", "P1")
        )
      end
      task
    end

    def ensure_qa_child(parent:, children:)
      task = stringify_keys(parent)
      return nil unless gated_role?(task["role"])
      return nil if valid_opt_out?(task)

      task_id = task["task_id"] || task["id"]
      already_exists = children.any? do |child|
        row = stringify_keys(child)
        row["role"] == "qa" && row["parent_task_id"].to_s == task_id.to_s
      end
      return nil if already_exists

      {
        "role" => "qa",
        "subject" => "QA Review: #{task['subject']}"[0, 121],
        "priority" => task.fetch("priority", "P1"),
        "status" => trusted_origin?(task["origin"]) ? "ready" : "pending",
        "origin" => normalized_origin(task["origin"]),
        "parent_task_id" => task_id
      }
    end

    def valid_opt_out?(task)
      row = stringify_keys(task)
      reason = row["no_chain_reason"].to_s.strip
      empty_chain = empty_chain?(row["next_tasks"])
      empty_chain && !reason.empty? && row["notes"].to_s.lines.any? do |line|
        line.strip == opt_out_note(role: row["role"], reason: reason)
      end
    end

    def validate_opt_out!(role:, no_chain:, reason:)
      return unless no_chain && gated_role?(role)
      return unless reason.to_s.strip.empty?

      raise RejectedOptOut,
        "--no-chain on a #{role} task requires --no-chain-reason \"<why QA is not applicable>\"; " \
        "the server persists this reason for audit"
    end

    def append_opt_out_note(notes, role:, reason:)
      line = opt_out_note(role: role, reason: reason)
      prior = notes.to_s.strip
      return line if prior.empty?
      return prior if prior.lines.any? { |existing| existing.strip == line }

      "#{prior}\n\n#{line}"
    end

    def opt_out_note(role:, reason:)
      "#{NOTE_PREFIX} (#{role}): #{reason.to_s.strip}"
    end

    def normalized_origin(origin)
      value = origin.to_s.strip
      value.empty? ? "internal" : value
    end

    def trusted_origin?(origin)
      normalized_origin(origin) == "internal"
    end

    def truthy?(value)
      value == true || value.to_s == "true"
    end

    def empty_chain?(value)
      return value.empty? if value.is_a?(Array) || value.is_a?(Hash)
      return false if value.nil?

      text = value.to_s.strip
      return false if text.empty?

      parsed = JSON.parse(text)
      parsed.nil? || ((parsed.is_a?(Array) || parsed.is_a?(Hash)) && parsed.empty?)
    rescue JSON::ParserError
      false
    end

    def stringify_keys(hash)
      hash.to_h.each_with_object({}) { |(key, value), output| output[key.to_s] = value }
    end
  end
end
