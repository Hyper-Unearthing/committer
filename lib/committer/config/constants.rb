# frozen_string_literal: true

module Committer
  module Config
    module Constants
      CONFIG_DIR = File.join(Dir.home, '.committer')
      DEFAULTS_PATH = File.join(File.dirname(__FILE__), './defaults')

      FORMATTING_RULES_FILE_NAME = 'formatting_rules.txt'
      CONFIG_FILE_NAME = 'config.yml'

      DEFAULT_CONFIG = {
        'api_key' => nil,
        'model' => 'claude-3-7-sonnet-20250219',
        'scopes' => nil
      }.freeze
    end
  end
end
