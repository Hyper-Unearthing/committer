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

        home_config = load_yml_file(read_file_from_home(Committer::Config::Constants::CONFIG_FILE_NAME))
        git_root_config = load_yml_file(read_file_from_git_root(Committer::Config::Constants::CONFIG_FILE_NAME))
        raise Committer::ConfigErrors::NotSetup if home_config.empty? && git_root_config.empty?

        unless home_config.is_a?(Hash) && git_root_config.is_a?(Hash)
          raise Committer::ConfigErrors::FormatError,
                'Config file must be a YAML hash'
        end

        # Merge configs with git root taking precedence
        home_config.merge(git_root_config)
      end

      def load_yml_file(contents)
        YAML.safe_load(contents, permitted_classes: [Symbol, NilClass, String, Array]) || {}
      end

      def read_file_from_path(path)
        return '' unless File.exist?(path)

        File.read(path)
      end

      def read_file_from_git_root(file_name)
        read_file_from_path(File.join(Committer::GitHelper.repo_root, '.committer', file_name))
      end

      def read_file_from_home(file_name)
        read_file_from_path(File.join(Committer::Config::Constants::CONFIG_DIR, file_name))
      end

      def load_default_file(file_name)
        read_file_from_path(File.join(Committer::Config::Constants::DEFAULTS_PATH, file_name))
      end

      def read_path_prioritized_file(file_name)
        git_path_contents = read_file_from_git_root(file_name)

        return git_path_contents unless git_path_contents.empty?

        home_path_contents = read_file_from_home(file_name)

        return home_path_contents unless home_path_contents.empty?

        load_default_file(file_name)
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
