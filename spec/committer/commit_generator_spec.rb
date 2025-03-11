# frozen_string_literal: true

require 'spec_helper'
require 'committer/commit_generator'

RSpec.describe Committer::CommitGenerator do
  let(:diff) { load_fixture('sample_diff.txt') }
  let(:commit_context) { nil }
  let(:summary_response) { JSON.parse(load_fixture('claude_response_summary.json')) }
  let(:body_response) { JSON.parse(load_fixture('claude_response_with_body.json')) }
  let(:client_instance) { instance_double(Clients::ClaudeClient) }
  let(:generator) { described_class.new(diff, commit_context) }
  let(:temp_home) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_home, '.committer') }
  let(:config_file) { File.join(config_dir, 'config.yml') }

  before do
    stub_const('Committer::Config::Constants::CONFIG_DIR', config_dir)
    stub_const('Committer::Config::Constants::CONFIG_FILE', config_file)
    allow(Dir).to receive(:home).and_return(temp_home)
    FileUtils.mkdir_p(config_dir)
    File.write(config_file, { api_key: 'dummyKey', scopes: [] }.to_yaml)
    Committer::Config::Accessor.instance.reload
  end

  after do
    FileUtils.remove_entry(temp_home) if File.directory?(temp_home)
  end

  describe '#build_commit_prompt' do
    context 'when no scopes are configured' do
      it 'builds prompt with no scopes' do
        prompt = generator.build_commit_prompt
        expect(prompt).to include('DO NOT include a scope in your commit message')
        expect(prompt).to include(diff)
        expect(prompt).not_to include('Scopes:')
      end
    end

    context 'when scopes are configured' do
      let(:scopes) { %w[api ui docs] }

      before do
        FileUtils.mkdir_p(config_dir)
        File.write(config_file, { api_key: 'dummyKey', scopes: %w[api ui docs] }.to_yaml)
        Committer::Config::Accessor.instance.reload
      end

      it 'builds prompt with scopes' do
        prompt = generator.build_commit_prompt
        expect(prompt).to include('Choose an appropriate scope from the list above')
        expect(prompt).to include('Scopes:')
        scopes.each do |scope|
          expect(prompt).to include("- #{scope}")
        end
        expect(prompt).to include(diff)
      end
    end

    context 'when commit context is provided' do
      let(:commit_context) { 'This is a version bump for the next release' }
      let(:generator) { described_class.new(diff, commit_context) }

      it 'uses the template with body' do
        prompt = generator.build_commit_prompt
        expect(prompt).to include(commit_context)
        expect(prompt).to include('Respond ONLY with the commit message text (message and body), nothing else.')
      end
    end

    context 'when no commit context is provided' do
      let(:commit_context) { nil }
      let(:generator) { described_class.new(diff, commit_context) }

      it 'uses summary-only template when commit context is nil' do
        prompt = generator.build_commit_prompt
        expect(prompt).to include('Respond ONLY with the commit message line, nothing else.')
      end
    end
  end

  describe '.check_git_status' do
    context 'when git diff command succeeds' do
      before do
        allow(Committer::GitHelper).to receive(:staged_diff).and_return(diff)
      end

      it 'returns the diff output' do
        expect(described_class.check_git_status).to eq(diff)
      end
    end

    context 'when git diff command fails' do
      before do
        allow(Committer::GitHelper).to receive(:staged_diff)
          .and_raise(Committer::Error.new('Failed to get git diff: error message'))
        # Stub exit to prevent spec from actually exiting
        allow(described_class).to receive(:exit).with(1)
        allow(described_class).to receive(:puts)
      end

      it 'outputs error message and exits' do
        expect(described_class).to receive(:puts).with('Failed to get git diff: error message')
        expect(described_class).to receive(:exit).with(1)
        described_class.check_git_status
      end
    end

    context 'when there are no staged changes' do
      before do
        allow(Committer::GitHelper).to receive(:staged_diff).and_return('')
      end

      it 'returns an empty string' do
        expect(described_class.check_git_status).to eq('')
      end
    end
  end

  describe '#prepare_commit_message' do
    context 'when called with diff and no context' do
      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: summary_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'builds prompt, calls API and parses response' do
        result = generator.prepare_commit_message
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to be_nil
      end
    end

    context 'when called with diff and context' do
      let(:commit_context) { 'Context for the commit' }
      let(:generator) { described_class.new(diff, commit_context) }

      before do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: body_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'builds prompt with context, calls API and parses response' do
        result = generator.prepare_commit_message
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to include('Incremented patch version')
      end
    end

    context 'when called with a different client' do
      let(:client_class) { class_double('Clients::SomeOtherClient', new: client_instance).as_stubbed_const }
      let(:client_instance) { instance_double('Clients::SomeOtherClient', post: nil) }
      let(:generator) { described_class.new(diff, commit_context) }

      before do
        allow(generator).to receive(:build_commit_prompt).and_return('my prompt')
        allow(generator).to receive(:parse_response)
        allow(client_instance).to receive(:post)
      end

      it 'builds the prompt and passes it to the client' do
        generator.prepare_commit_message(client_class)

        expect(client_instance).to have_received(:post).with('my prompt')
      end
    end
  end
end
