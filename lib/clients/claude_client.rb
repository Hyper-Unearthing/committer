# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative '../committer/config/accessor'

module Clients
  # Claude API client for communicating with Anthropic's Claude model
  class ClaudeClient
    class OverloadError < StandardError; end
    class UnknownError < StandardError; end
    class ConfigError < StandardError; end

    API_ENDPOINT = 'https://api.anthropic.com/v1/messages'

    def initialize
      @config = Committer::Config::Accessor.instance

      return unless @config['api_key'].nil? || @config['api_key'].empty?

      raise ConfigError,
            "API key not configured. Run 'committer setup' and edit ~/.committer/config.yml to add your API key."
    end

    def post(message)
      body = {
        model: @config['model'],
        max_tokens: 4096,
        messages: [
          { role: 'user', content: message }
        ]
      }

      response = send_request(body)
      handle_error_response(response) if response['type'] == 'error'

      response
    end

    private

    def send_request(body)
      uri = URI.parse(API_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request['anthropic-version'] = '2023-06-01'
      request['content-type'] = 'application/json'
      request['x-api-key'] = @config['api_key']
      request.body = body.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue JSON::ParserError
      { 'type' => 'error', 'error' => { 'type' => 'unknown_error' } }
    end

    def handle_error_response(response)
      error = response['error']
      raise OverloadError if error['type'] == 'overloaded_error'

      puts response
      raise UnknownError, "Claude API error: #{response.inspect}"
    end
  end
end
