# frozen_string_literal: true

require_relative '../config/writer'
require_relative '../config/constants'

module Committer
  module Commands
    class Setup
      def self.execute(_args)
        config_dir = Committer::Config::Constants::CONFIG_DIR
        writer = Committer::Config::Writer.new(config_dir)
        writer.setup
        exit 0
      end
    end
  end
end
