# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Committer
  class Config
    CONFIG_DIR = File.join(Dir.home, '.committer')
    CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')
    DEFAULT_CONFIG = {
      'api_key' => nil,
      'model' => 'claude-3-sonnet-20240229'
    }.freeze

    def self.load
      create_default_config unless File.exist?(CONFIG_FILE)
      begin
        YAML.load_file(CONFIG_FILE) || DEFAULT_CONFIG
      rescue StandardError => e
        puts "Error loading config: #{e.message}"
        DEFAULT_CONFIG
      end
    end

    def self.create_default_config
      FileUtils.mkdir_p(CONFIG_DIR) unless Dir.exist?(CONFIG_DIR)
      File.write(CONFIG_FILE, DEFAULT_CONFIG.to_yaml)
    end

    def self.setup
      create_default_config
      puts 'Created config file at:'
      puts CONFIG_FILE
      puts "\nPlease edit this file to add your Anthropic API key."
      puts 'Example config format:'
      puts '---'
      puts 'api_key: your_api_key_here'
      puts 'model: claude-3-sonnet-20240229'
    end
  end
end
