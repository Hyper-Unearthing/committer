# frozen_string_literal: true

module Committer
  module PromptTemplates
    def self.build_prompt(diff, scopes, commit_context)
      prompt_template = if commit_context.nil? || commit_context.empty?
                          Committer::PromptTemplates.build_prompt_summary_only
                        else
                          Committer::PromptTemplates.build_prompt_summary_and_body
                        end
      prompt_template
        .gsub('{{DIFF}}', diff)
        .gsub('{{SCOPES}}', build_scopes_list(scopes))
        .gsub('{{CONTEXT}}', commit_context || '')
    end

    def self.build_scopes_list(scopes)
      return 'DO NOT include a scope in your commit message' if scopes.empty?

      scope_list = "\nScopes:\n#{scopes.map { |s| "- #{s}" }.join("\n")}"

      "- Choose an appropriate scope from the list above if relevant to the change \n#{scope_list}"
    end

    def self.build_prompt_summary_only
      load_prompt(Committer::Config::Constants::COMMIT_MESSAGE_ONLY_PROMPT_FILE_NAME)
    end

    def self.build_prompt_summary_and_body
      load_prompt(Committer::Config::Constants::COMMIT_MESSAGE_AND_BODY_PROMPT_FILE_NAME)
    end

    def self.load_prompt(file_name)
      Committer::Config::Accessor.instance.read_path_prioritized_file(file_name)
    end
  end
end
