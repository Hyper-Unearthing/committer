# frozen_string_literal: true

require 'yaml'
require_relative 'config/accessor'
require_relative 'prompt_templates'
require_relative '../clients/claude_client'
require_relative 'git_helper'

module Committer
  class CommitGenerator
    attr_reader :diff, :commit_context

    def initialize(diff, commit_context = nil)
      @diff = diff
      @commit_context = commit_context
    end

    def build_commit_prompt
      format(template,
             diff: @diff,
             commit_context: @commit_context)
    end

    def template
      if @commit_context.nil? || @commit_context.empty?
        Committer::PromptTemplates.build_prompt_summary_only
      else
        Committer::PromptTemplates.build_prompt_summary_and_body
      end
    end

    def self.check_git_status
      Committer::GitHelper.staged_diff
    rescue Committer::Error => e
      puts e.message
      exit 1
    end

    def parse_response(response)
      text = response.dig('content', 0, 'text')

      # If user didn't provide context, response should only be a summary line
      if @commit_context.nil? || @commit_context.empty?
        { summary: text.strip, body: nil }
      else
        # Split the response into summary and body
        message_parts = text.split("\n\n", 2)
        summary = message_parts[0].strip
        body = message_parts[1]&.strip

        # Wrap body text at 80 characters
        body = body.gsub(/(.{1,80})(\s+|$)/, "\\1\n").strip if body

        { summary: summary, body: body }
      end
    end

    def prepare_commit_message(client_class = Clients::ClaudeClient)
      client = client_class.new

      prompt = build_commit_prompt
      response = client.post(prompt)
      parse_response(response)
    end
  end
end
