# frozen_string_literal: true

module Committer
  module Commands
    class Default
      def self.execute_commit(diff, commit_context)
        commit_generator = Committer::CommitGenerator.new(diff, commit_context)
        commit_message = commit_generator.prepare_commit_message

        summary = commit_message[:summary]
        body = commit_message[:body]
        # Create git commit with the suggested message and open in editor
        if body
          system('git', 'commit', '-m', summary, '-m', body, '-e')
        else
          system('git', 'commit', '-m', summary, '-e')
        end
      end

      def self.execute(_args)
        diff = Committer::CommitGenerator.check_git_status

        if diff.empty?
          puts 'No changes are staged for commit.'
          exit 0
        end

        # Prompt user for commit context
        puts 'Why are you making this change? (Press Enter to skip)'
        commit_context = gets.chomp
        execute_commit(diff, commit_context)
      rescue Clients::ClaudeClient::ConfigError, StandardError => e
        puts "Error: #{e.message}"
        exit 1
      end
    end
  end
end
