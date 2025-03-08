# frozen_string_literal: true

module Committer
  module PromptTemplates
    def self.load_formatting_rules
      Committer::Config::Accessor.instance.load_formatting_rules
    end

    def self.load_scopes
      scopes = Committer::Config::Accessor.instance[:scopes] || []
      return 'DO NOT include a scope in your commit message' if scopes.empty?

      scope_list = "\nScopes:\n#{scopes.map { |s| "- #{s}" }.join("\n")}"

      "- Choose an appropriate scope from the list above if relevant to the change \n#{scope_list}"
    end

    def self.commit_message_guidelines
      <<~PROMPT
        #{load_formatting_rules}

        # Formatting rules with body:
        <message>

        <blank line>
        <body with more detailed explanation>

        #{load_scopes}

        # Message Guidelines:
        - Keep the summary under 70 characters
        - Use imperative, present tense (e.g., "add" not "added" or "adds")
        - Do not end the summary with a period
        - Be concise but descriptive in the summary

        # Body Guidelines:
        - Add a blank line between summary and body
        - Use the body to explain why the change was made, incorporating the user's context
        - Wrap each line in the body at 80 characters maximum
        - Break the body into multiple paragraphs if needed

        Git Diff:
        ```
        %<diff>s
        ```
      PROMPT
    end

    def self.build_prompt_summary_only
      <<~PROMPT
        Below is a git diff of staged changes. Please analyze it and create a commit message following the formatting rules format with ONLY a message line (NO body):

        #{commit_message_guidelines}

        Respond ONLY with the commit message line, nothing else.
      PROMPT
    end

    def self.build_prompt_summary_and_body
      <<~PROMPT
        Below is a git diff of staged changes. Please analyze it and create a commit message following the formatting rules format with a summary line and a detailed body:

        #{commit_message_guidelines}
        User's context for this change: %<commit_context>s

        Respond ONLY with the commit message text (message and body), nothing else.
      PROMPT
    end
  end
end
