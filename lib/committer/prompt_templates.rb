# frozen_string_literal: true

module Committer
  module PromptTemplates
    SUMMARY_ONLY = <<~PROMPT
      Below is a git diff of staged changes. Please analyze it and create a commit message following the Conventional Commits format with ONLY a summary line (NO body):

      Format: <type>(<optional scope>): <description>

      Types:
      - feat: A new feature
      - fix: A bug fix
      - docs: Documentation only changes
      - style: Changes that do not affect the meaning of the code
      - refactor: A code change that neither fixes a bug nor adds a feature
      - perf: A code change that improves performance
      - test: Adding missing tests or correcting existing tests
      - chore: Changes to the build process or auxiliary tools

      Guidelines:
      - Keep the summary under 70 characters
      - Use imperative, present tense (e.g., "add" not "added" or "adds")
      - Do not end the summary with a period
      - Be concise but descriptive in the summary

      Git Diff:
      ```
      %<diff>s
      ```

      Respond ONLY with the commit message summary line, nothing else.
    PROMPT

    SUMMARY_AND_BODY = <<~PROMPT
      Below is a git diff of staged changes. Please analyze it and create a commit message following the Conventional Commits format with a summary line and a detailed body:

      Format: <type>(<optional scope>): <description>

      <blank line>
      <body with more detailed explanation>

      Types:
      - feat: A new feature
      - fix: A bug fix
      - docs: Documentation only changes
      - style: Changes that do not affect the meaning of the code
      - refactor: A code change that neither fixes a bug nor adds a feature
      - perf: A code change that improves performance
      - test: Adding missing tests or correcting existing tests
      - chore: Changes to the build process or auxiliary tools

      Guidelines:
      - Keep the first line (summary) under 70 characters
      - Use imperative, present tense (e.g., "add" not "added" or "adds")
      - Do not end the summary with a period
      - Be concise but descriptive in the summary
      - Add a blank line between summary and body
      - Use the body to explain why the change was made, incorporating the user's context
      - Wrap each line in the body at 80 characters maximum
      - Break the body into multiple paragraphs if needed

      User's context for this change: %<commit_context>s

      Git Diff:
      ```
      %<diff>s
      ```

      Respond ONLY with the commit message text (summary and body), nothing else.
    PROMPT
  end
end
