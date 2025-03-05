# frozen_string_literal: true

require 'json'
require 'httparty'
require_relative '../committer/config'

module Clients
  class ClaudeClient
    class OverloadError < StandardError; end
    class UnknownError < StandardError; end
    class ConfigError < StandardError; end

    def initialize
      @config = Committer::Config.load

      return unless @config['api_key'].nil? || @config['api_key'].empty?

      raise ConfigError,
            "API key not configured. Run 'committer setup' and edit ~/.committer/config.yml to add your API key."
    end

    def post(message)
      body = {
        'model': @config['model'],
        'max_tokens': 4096,
        'messages': [
          { 'role': 'user', 'content': message }
        ]
      }
      options = {
        headers: {
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
          'x-api-key': @config['api_key']
        },
        body: body.to_json
      }
      response = HTTParty.post(
        'https://api.anthropic.com/v1/messages', options
      )
      if response['type'] == 'error'
        error = response['error']
        raise OverloadError if error['type'] == 'overloaded_error'

        puts response
        raise UnknownError, "Claude API error: #{response.inspect}"
      end
      response
    end
  end
end
