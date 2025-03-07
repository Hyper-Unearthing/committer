# frozen_string_literal: true

require_relative 'commands/setup'
require_relative 'commands/help'
require_relative 'commands/output_message'
require_relative 'commands/default'

module Committer
  module Commands
    def self.run(command, args)
      case command
      when 'setup'
        Setup.execute(args)
      when 'help', '--help', '-h'
        Help.execute(args)
      when 'output-message'
        OutputMessage.execute(args)
      else
        Default.execute(args)
      end
    end
  end
end
