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

      def create_default_config
        FileUtils.mkdir_p(@config_dir)
        if File.exist?(config_file)
          puts "Config file already exists at #{config_file}, skipping write"
        else
          File.write(config_file, Committer::Config::Constants::DEFAULT_CONFIG.to_yaml)
        end
      end
    end
  end
end
