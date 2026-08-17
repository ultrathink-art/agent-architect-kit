#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/qa_chain_contract"

module AgentArchitectKit
  # Executable, framework-neutral reference for the authoritative server
  # boundary. Port these transitions into your authenticated task create and
  # complete endpoints; do not treat the client-side default as enforcement.
  class ReferenceQaChainServer
    attr_reader :tasks

    def initialize
      @tasks = []
      @sequence = 0
    end

    def create(attributes)
      persist(QaChainContract.normalize_server_create(attributes))
    end

    # Represents a task inserted through another trusted server-side path. The
    # completion fallback still applies even when no client default was stored.
    def import(attributes)
      persist(QaChainContract.stringify_keys(attributes))
    end

    def complete(task_id)
      parent = find(task_id)
      raise KeyError, "Task not found: #{task_id}" unless parent

      parent["status"] = "completed"
      spawn_declared_children(parent)
      fallback = QaChainContract.ensure_qa_child(parent: parent, children: tasks)
      persist(fallback) if fallback
      parent
    end

    def children_of(task_id)
      tasks.select { |task| task["parent_task_id"].to_s == task_id.to_s }
    end

    private

    def persist(attributes)
      task = QaChainContract.stringify_keys(attributes)
      @sequence += 1
      task["task_id"] ||= "WQ-#{format('%03d', @sequence)}"
      task["status"] ||= "pending"
      task["origin"] = QaChainContract.normalized_origin(task["origin"])
      tasks << task
      task
    end

    def find(task_id)
      tasks.find { |task| task["task_id"].to_s == task_id.to_s }
    end

    def spawn_declared_children(parent)
      Array(parent["next_tasks"]).each do |definition|
        row = QaChainContract.stringify_keys(definition)
        duplicate = children_of(parent["task_id"]).any? do |child|
          child["role"] == row["role"] && child["subject"] == row["subject"]
        end
        next if duplicate

        persist(
          row.merge(
            "status" => QaChainContract.trusted_origin?(parent["origin"]) ? "ready" : "pending",
            "origin" => parent["origin"],
            "parent_task_id" => parent["task_id"]
          )
        )
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  server = AgentArchitectKit::ReferenceQaChainServer.new
  parent = server.import(
    "task_id" => "WQ-RAW",
    "role" => "coder",
    "subject" => "Raw API task without a client chain",
    "origin" => "untrusted",
    "status" => "in_progress"
  )
  server.complete(parent["task_id"])
  child = server.children_of(parent["task_id"]).first
  abort "QA contract failed" unless child && child["role"] == "qa" && child["status"] == "pending"

  puts "OK: completion created one pending QA child and preserved untrusted origin"
end
