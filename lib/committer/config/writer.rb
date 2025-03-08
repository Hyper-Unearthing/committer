# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative '../committer_errors'
require_relative 'accessor'

module Committer
  module Config
    class Writer
      CONFIG_DIR = Accessor::CONFIG_DIR
      CONFIG_FILE = Accessor::CONFIG_FILE
      DEFAULT_CONFIG = Accessor::DEFAULT_CONFIG

      def self.setup
        create_default_config
        puts 'Created config file at:'
        puts CONFIG_FILE
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

      def self.create_default_config
        FileUtils.mkdir_p(CONFIG_DIR)
        if File.exist?(CONFIG_FILE)
          puts "Config file already exists at #{CONFIG_FILE}, skipping write"
        else
          File.write(CONFIG_FILE, DEFAULT_CONFIG.to_yaml)
        end
      end
    end
  end
end
