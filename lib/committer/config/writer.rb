# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative '../committer_errors'
require_relative 'constants'

module Committer
  module Config
    class Writer
      attr_reader :config_dir

      def initialize(config_dir)
        @config_dir = config_dir
      end

      def config_file
        File.join(@config_dir, Committer::Config::Constants::CONFIG_FILE_NAME)
      end

      def setup
        create_default_config
        create_sample_formatting_rules
      end

      def write_config_file(file_path, contents)
        FileUtils.mkdir_p(@config_dir)
        if File.exist?(file_path)
          puts "Config file already exists at #{config_file}, skipping write"
          false
        else
          File.write(file_path, contents)
          true
        end
      end

      def create_sample_formatting_rules
        default_formatting_rules = File.read(File.join(Committer::Config::Constants::DEFAULT_PROMPT_PATH,
                                                       Committer::Config::Constants::FORMATTING_RULES_FILE_NAME))
        formatting_rules_file = File.join(@config_dir,
                                          "#{Committer::Config::Constants::FORMATTING_RULES_FILE_NAME}.sample")
        wrote_file = write_config_file(formatting_rules_file, default_formatting_rules)
        nil unless wrote_file
      end

      def create_default_config
        wrote_file = write_config_file(config_file, Committer::Config::Constants::DEFAULT_CONFIG.to_yaml)
        return unless wrote_file

        puts 'Created config file at:'
        puts config_file
        puts "\nPlease edit this file to add your Anthropic API key."
        puts 'Example config format:'
        puts '---'
        puts 'api_key: your_api_key_here'
        puts 'model: claude-3-7-sonnet-20250219'
        puts 'scopes:'
        puts '  - feature'
        puts '  - api'
        puts '  - ui'
      end
    end
  end
end
