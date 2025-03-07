# frozen_string_literal: true

module Committer
  # Configuration management for the Committer gem
  class ConfigErrors
    class BaseError < StandardError; end

    # Request Processing Errors
    class FormatError < BaseError; end
    class NotSetup < BaseError; end
  end
end
