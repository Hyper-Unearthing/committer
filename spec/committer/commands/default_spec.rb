# frozen_string_literal: true

require 'spec_helper'
require 'committer/commands/default'

RSpec.describe Committer::Commands::Default do
  let(:diff) { 'sample diff content' }
  let(:commit_context) { 'Test commit context' }
  let(:commit_message) { { summary: 'feat: add new feature', body: 'This is the commit body' } }
  let(:commit_generator) { instance_double(Committer::CommitGenerator) }

  describe '.execute' do
    before do
      allow(Committer::CommitGenerator).to receive(:check_git_status).and_return(diff)
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:gets).and_return(commit_context)
      allow(described_class).to receive(:execute_commit)
      allow(described_class).to receive(:exit)
    end

    context 'when there are staged changes' do
      it 'prompts for commit context and executes commit' do
        expect(described_class).to receive(:puts).with('Why are you making this change? (Press Enter to skip)')
        expect(described_class).to receive(:execute_commit).with(diff, commit_context)

        described_class.execute([])
      end
    end

    context 'when there are no staged changes' do
      let(:diff) { '' }

      it 'shows a message and exits' do
        expect(described_class).to receive(:puts).with('No changes are staged for commit.')
        expect(described_class).to receive(:exit).with(0)

        described_class.execute([])
      end
    end

    context 'when an error occurs' do
      before do
        allow(Committer::CommitGenerator).to receive(:check_git_status).and_raise(StandardError.new('Test error'))
      end

      it 'shows the error message and exits' do
        expect(described_class).to receive(:puts).with('Error: Test error')
        expect(described_class).to receive(:exit).with(1)

        described_class.execute([])
      end

      it 'handles ConfigError' do
        expected_error = Clients::ClaudeClient::ConfigError.new('Config error')
        allow(Committer::CommitGenerator).to receive(:check_git_status).and_raise(expected_error)
        expect(described_class).to receive(:puts).with('Error: Config error')
        expect(described_class).to receive(:exit).with(1)

        described_class.execute([])
      end
    end
  end

  describe '.execute_commit' do
    before do
      allow(Committer::CommitGenerator).to receive(:new).with(diff, commit_context).and_return(commit_generator)
      allow(commit_generator).to receive(:prepare_commit_message).and_return(commit_message)
      allow(Committer::GitHelper).to receive(:commit)
    end

    context 'when commit includes a body' do
      it 'creates a commit with summary and body' do
        expect(Committer::GitHelper).to receive(:commit).with(commit_message[:summary], commit_message[:body])

        described_class.execute_commit(diff, commit_context)
      end
    end

    context 'when commit has no body' do
      let(:commit_message) { { summary: 'feat: add new feature', body: nil } }

      it 'creates a commit with only the summary' do
        expect(Committer::GitHelper).to receive(:commit).with(commit_message[:summary], nil)

        described_class.execute_commit(diff, commit_context)
      end
    end
  end
end
