# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Clients::ClaudeClient do
  let(:config) { { 'api_key' => 'test_api_key', 'model' => 'test_model' } }
  let(:valid_response) { JSON.parse(File.read(fixture_path('claude_response_summary.json'))) }
  let(:error_response) { { 'type' => 'error', 'error' => { 'type' => 'overloaded_error' } } }

  before do
    # Create and stub the Config singleton instance
    allow_any_instance_of(Committer::Config).to receive(:to_h).and_return(config)
    allow_any_instance_of(Committer::Config).to receive(:[]) { |_, key| config[key] }

    # Stub WebMock to allow specific requests
    WebMock.disable_net_connect!

    # Reset the singleton before each test
    Singleton.__init__(Committer::Config)
  end

  describe '#initialize' do
    context 'with a valid API key' do
      it 'initializes without errors' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'with a missing API key' do
      let(:config) { { 'api_key' => nil, 'model' => 'test_model' } }

      it 'raises a ConfigError' do
        expect { described_class.new }.to raise_error(Clients::ClaudeClient::ConfigError)
      end
    end

    context 'with an empty API key' do
      let(:config) { { 'api_key' => '', 'model' => 'test_model' } }

      it 'raises a ConfigError' do
        expect { described_class.new }.to raise_error(Clients::ClaudeClient::ConfigError)
      end
    end
  end

  describe '#post' do
    let(:client) { described_class.new }
    let(:message) { 'Test message' }

    before do
      stub_request(:post, 'https://api.anthropic.com/v1/messages')
        .with(
          headers: {
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
            'x-api-key': 'test_api_key'
          }
        )
        .to_return(status: 200, body: valid_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'includes the correct request body' do
      client.post(message)
      expect(WebMock).to(have_requested(:post, 'https://api.anthropic.com/v1/messages')
        .with { |req| JSON.parse(req.body)['messages'][0]['content'] == message })
    end

    it 'returns the API response' do
      response = client.post(message)
      # Comparing the HTTParty response directly doesn't work well
      # Instead check that it contains the expected content
      expect(response.dig('content', 0, 'text')).to eq(valid_response.dig('content', 0, 'text'))
      expect(response['id']).to eq(valid_response['id'])
    end

    context 'when API returns an error' do
      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 500, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises OverloadError for overloaded_error type' do
        expect { client.post(message) }.to raise_error(Clients::ClaudeClient::OverloadError)
      end
    end

    context 'when API returns an unknown error' do
      before do
        error_resp = error_response.dup
        error_resp['error']['type'] = 'unknown_error'
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 500, body: error_resp.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises UnknownError for other error types' do
        # Stub puts to avoid polluting test output
        allow_any_instance_of(Clients::ClaudeClient).to receive(:puts)
        expect { client.post(message) }.to raise_error(Clients::ClaudeClient::UnknownError)
      end
    end
  end
end
