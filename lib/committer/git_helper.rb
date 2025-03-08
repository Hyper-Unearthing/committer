# frozen_string_literal: true

require 'open3'

module Committer
  # Helper class for git operations
  class GitHelper
    class << self
      def commit(summary, body = nil)
        if body
          system('git', 'commit', '-m', summary, '-m', body, '-e')
        else
          system('git', 'commit', '-m', summary, '-e')
        end
      end

      def repo_root
        `git rev-parse --show-toplevel`.strip
      end

      def staged_diff
        stdout, stderr, status = Open3.capture3('git diff --staged')
        raise Committer::Error, "Failed to get git diff: #{stderr}" unless status.success?

        stdout
      end
    end
  end
end
