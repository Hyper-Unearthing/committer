# frozen_string_literal: true

require 'yaml'
require 'singleton'
require_relative '../committer_errors'
require_relative 'constants'
require_relative '../git_helper'

module Committer
  # Configuration management for the Committer gem
  module Config
    class Accessor
      include Singleton

      def initialize
        @config = load_config
      end

      # Accessor for the loaded config
      def [](key)
        @config[key.to_sym] || @config[key.to_s]
      end

      # Get the entire config hash
      def to_h
        @config.dup
      end

      def load_config
        # Load configs from both locations and merge them
        home_config = load_config_from_path(Committer::Config::Constants::CONFIG_FILE)
        git_root_config = load_config_from_git_root
        raise Committer::ConfigErrors::NotSetup if home_config.empty? && git_root_config.empty?

        # Merge configs with git root taking precedence
        home_config.merge(git_root_config)
      end

      def load_config_from_path(path)
        return {} unless File.exist?(path)

        result = YAML.load_file(path)
        raise Committer::ConfigErrors::FormatError, 'Config file must be a YAML hash' unless result.is_a?(Hash)

        result
      end

      def load_file_from_path(path)
        return '' unless File.exist?(path)

        File.read(path)
      end

      def load_formatting_rules
        git_root = Committer::GitHelper.repo_root
        unless git_root.empty?
          formatting_rules_git_path = File.join(git_root, '.committer',
                                                Committer::Config::Constants::FORMATTING_RULES_FILE_NAME)
        end

        git_path_contents = load_file_from_path(formatting_rules_git_path) if formatting_rules_git_path

        return git_path_contents unless git_path_contents.empty?

        home_path = File.join(Committer::Config::Constants::CONFIG_DIR,
                              Committer::Config::Constants::FORMATTING_RULES_FILE_NAME)

        home_path_contents = load_file_from_path(home_path)

        return home_path_contents unless home_path_contents.empty?

        default_path = File.join(Committer::Config::Constants::DEFAULT_PROMPT_PATH,
                                 Committer::Config::Constants::FORMATTING_RULES_FILE_NAME)
        load_file_from_path(default_path)
      end

      def load_config_from_git_root
        git_root = Committer::GitHelper.repo_root
        return {} if git_root.empty?

        git_config_file = File.join(git_root, '.committer', 'config.yml')
        load_config_from_path(git_config_file)
      rescue StandardError
        {}
      end

      # Force reload configuration (useful for testing)
      def reload
        @config = load_config
      end

      # Class method for reload
      def self.reload
        instance.reload
      end
    end
  end
end
