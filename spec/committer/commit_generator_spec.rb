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

  before do
    allow(Clients::ClaudeClient).to receive(:new).and_return(client_instance)
  end

  describe '#build_commit_prompt' do
    context 'when no scopes are configured' do
      before do
        allow(Committer::Config).to receive(:load).and_return([])
      end

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
        allow(Committer::Config).to receive(:load).and_return(scopes)
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

      before do
        allow(Committer::Config).to receive(:load).and_return([])
      end

      it 'uses the template with body' do
        expect(generator).to receive(:template).and_call_original
        prompt = generator.build_commit_prompt
        expect(prompt).to include(commit_context)
        expect(prompt).to include('summary and body')
      end
    end
  end

  describe '#template' do
    context 'when commit context is nil or empty' do
      it 'returns SUMMARY_ONLY template when nil' do
        expect(generator.template).to eq(Committer::PromptTemplates::SUMMARY_ONLY)
      end

      it 'returns SUMMARY_ONLY template when empty' do
        generator = described_class.new(diff, '')
        expect(generator.template).to eq(Committer::PromptTemplates::SUMMARY_ONLY)
      end
    end

    context 'when commit context is provided' do
      let(:commit_context) { 'some context' }
      let(:generator) { described_class.new(diff, commit_context) }

      it 'returns SUMMARY_AND_BODY template' do
        expect(generator.template).to eq(Committer::PromptTemplates::SUMMARY_AND_BODY)
      end
    end
  end

  describe '.check_git_status' do
    context 'when git diff command succeeds' do
      before do
        allow(Open3).to receive(:capture3).with('git diff --staged').and_return([diff, '', double(success?: true)])
      end

      it 'returns the diff output' do
        expect(described_class.check_git_status).to eq(diff)
      end
    end

    context 'when git diff command fails' do
      let(:error_message) { 'fatal: not a git repository' }

      before do
        allow(Open3).to receive(:capture3).with('git diff --staged').and_return(['', error_message,
                                                                                 double(success?: false)])
        # Stub exit to prevent spec from actually exiting
        allow(described_class).to receive(:exit)
        allow(described_class).to receive(:puts)
      end

      it 'outputs error message and exits' do
        expect(described_class).to receive(:puts).with('Error executing git diff --staged:')
        expect(described_class).to receive(:puts).with(error_message)
        expect(described_class).to receive(:exit).with(1)
        described_class.check_git_status
      end
    end

    context 'when there are no staged changes' do
      before do
        allow(Open3).to receive(:capture3).with('git diff --staged').and_return(['', '', double(success?: true)])
        # Stub exit to prevent spec from actually exiting
        allow(described_class).to receive(:exit)
        allow(described_class).to receive(:puts)
      end

      it 'outputs message and exits' do
        expect(described_class.check_git_status).to eq('')
      end
    end
  end

  describe '#parse_response' do
    context 'when commit context is nil or empty' do
      it 'returns only summary when context is nil' do
        result = generator.parse_response(summary_response)
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to be_nil
      end

      it 'returns only summary when context is empty' do
        generator = described_class.new(diff, '')
        result = generator.parse_response(summary_response)
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to be_nil
      end
    end

    context 'when commit context is provided' do
      let(:commit_context) { 'Some context for the commit' }
      let(:generator) { described_class.new(diff, commit_context) }

      it 'returns summary and body' do
        result = generator.parse_response(body_response)
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to include('Incremented patch version')
        # Verify body was wrapped at 80 characters
        body_lines = result[:body].split("\n")
        body_lines.each do |line|
          expect(line.length).to be <= 80
        end
      end
    end
  end

  describe '#prepare_commit_message' do
    context 'when called with diff and no context' do
      before do
        allow(client_instance).to receive(:post).and_return(summary_response)
        allow(generator).to receive(:puts)
      end

      it 'builds prompt, calls API and parses response' do
        expect(generator).to receive(:build_commit_prompt).and_call_original
        expect(client_instance).to receive(:post)
        expect(generator).to receive(:parse_response).with(summary_response).and_call_original

        result = generator.prepare_commit_message
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to be_nil
      end
    end

    context 'when called with diff and context' do
      let(:commit_context) { 'Context for the commit' }
      let(:generator) { described_class.new(diff, commit_context) }

      before do
        allow(client_instance).to receive(:post).and_return(body_response)
        allow(generator).to receive(:puts)
      end

      it 'builds prompt with context, calls API and parses response' do
        expect(generator).to receive(:build_commit_prompt).and_call_original
        expect(client_instance).to receive(:post)
        expect(generator).to receive(:parse_response).with(body_response).and_call_original

        result = generator.prepare_commit_message
        expect(result[:summary]).to eq('chore: bump version from 0.1.0 to 0.1.1')
        expect(result[:body]).to include('Incremented patch version')
      end
    end

    context 'when called with a different client' do
      class Clients::SomeOtherClient
        def post(_prompt); end
      end

      let(:client_instance) { instance_double(Clients::SomeOtherClient) }
      let(:generator) { described_class.new(diff, commit_context) }

      before do
        allow(Clients::SomeOtherClient).to receive(:new).and_return(client_instance)
        allow(generator).to receive(:build_commit_prompt).and_return('my prompt')
        allow(generator).to receive(:parse_response)
        allow(client_instance).to receive(:post)
      end

      it 'builds the prompt and passes it to the client' do
        generator.prepare_commit_message(Clients::SomeOtherClient)

        expect(client_instance).to have_received(:post).with('my prompt')
      end
    end
  end
end
