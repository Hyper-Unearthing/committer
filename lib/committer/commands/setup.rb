# frozen_string_literal: true

require_relative '../config/writer'

module Committer
  module Commands
    class Setup
      def self.execute(_args)
        Committer::Config::Writer.setup
        exit 0
      end
    end
  end
end
