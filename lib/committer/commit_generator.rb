# frozen_string_literal: true

require 'open3'
require 'httparty'
require 'yaml'
require_relative 'config'
require_relative 'prompt_templates'
require_relative '../clients/claude_client'

module Committer
  class CommitGenerator
    attr_reader :diff, :commit_context

    def initialize(diff, commit_context = nil)
      @diff = diff
      @commit_context = commit_context
    end

    def build_commit_prompt
      scopes = Committer::Config.load
      scope_section = scopes.empty? ? '' : "\nScopes:\n#{scopes.map { |s| "- #{s}" }.join("\n")}"
      scope_instruction = if scopes.empty?
                            '- DO NOT include a scope in your commit message'
                          else
                            '- Choose an appropriate scope from the list above if relevant to the change'
                          end
      format(template,
             diff: @diff,
             scopes_section: scope_section,
             scope_instruction: scope_instruction,
             commit_context: @commit_context)
    end

    def template
      if @commit_context.nil? || @commit_context.empty?
        Committer::PromptTemplates::SUMMARY_ONLY
      else
        Committer::PromptTemplates::SUMMARY_AND_BODY
      end
    end

    def self.check_git_status
      stdout, stderr, status = Open3.capture3('git diff --staged')

      unless status.success?
        puts 'Error executing git diff --staged:'
        puts stderr
        exit 1
      end

      if stdout.empty?
        puts 'No changes are staged for commit.'
        exit 0
      end

      stdout
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

    def prepare_commit_message
      client = Clients::ClaudeClient.new

      prompt = build_commit_prompt
      response = client.post(prompt)
      parse_response(response)
    end
  end
end
