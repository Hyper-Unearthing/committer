# frozen_string_literal: true

module Committer
  module Commands
    class Help
      def self.execute(_args)
        puts 'Committer - AI-powered git commit message generator'
        puts
        puts 'Commands:'
        puts '  committer setup          - Create the config file template at ~/.committer/config.yml'
        puts '  committer                - Generate commit message for staged changes'
        puts '  committer output-message - Generate commit message without creating a commit'
        puts '  committer setup-git-hook - Install the prepare-commit-msg git hook'
        puts
        exit 0
      end
    end
  end
end
