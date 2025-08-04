# frozen_string_literal: true

module Committer
  module Commands
    class OutputMessage
      def self.execute(args)
        commit_context = args[0]
        diff = Committer::CommitGenerator.check_git_status

        commit_generator = Committer::CommitGenerator.new(diff, commit_context)
        commit_message = commit_generator.prepare_commit_message

        summary = commit_message[:summary]
        body = commit_message[:body]

        puts <<~OUTPUT
          #{summary}

          #{body}
        OUTPUT
        exit 0
      rescue StandardError => e
        puts "Error: #{e.message}"
        exit 1
      rescue StandardError
        exit 0
      end
    end
  end
end
