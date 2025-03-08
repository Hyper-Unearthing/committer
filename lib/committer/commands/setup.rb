# frozen_string_literal: true

module Committer
  module Commands
    class Setup
      def self.execute(_args)
        Committer::Config::Accessor.setup
        exit 0
      end
    end
  end
end
