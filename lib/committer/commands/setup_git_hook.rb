# frozen_string_literal: true

require_relative '../git_helper'

module Committer
  module Commands
    class SetupGitHook
      HOOK_PATH = '.git/hooks/prepare-commit-msg'

      def self.execute(_args)
        validate_git_repository
        install_git_hook
        display_success_message
        exit 0
      rescue StandardError => e
        puts "Error: #{e.message}"
        exit 1
      end

      def self.validate_git_repository
        validate_git_root
        validate_git_directory_exists
        validate_hook_doesnt_exist
      end

      def self.validate_git_directory_exists
        return if Dir.exist?('.git')

        puts 'Error: Current directory is not a git repository.'
        exit 1
      end

      def self.validate_git_root
        git_toplevel = Committer::GitHelper.repo_root
        current_dir = Dir.pwd
        return if git_toplevel == current_dir

        puts 'Error: Please run this command from the root of your git repository.'
        exit 1
      end

      def self.validate_hook_doesnt_exist
        return unless File.exist?(HOOK_PATH)

        puts 'Error: prepare-commit-msg hook already exists.'
        puts 'Please remove or rename the existing hook and try again.'
        exit 1
      end

      def self.install_git_hook
        template_path = File.expand_path('../prepare-commit-msg', __dir__)
        hook_content = File.read(template_path)
        File.write(HOOK_PATH, hook_content)
        File.chmod(0o755, HOOK_PATH)
      end

      def self.display_success_message
        puts 'Git hook successfully installed!'
        puts 'Now your commit messages will be automatically generated.'
      end
    end
  end
end
