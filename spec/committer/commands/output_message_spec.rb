# frozen_string_literal: true

require 'spec_helper'
require 'committer/commands/output_message'

RSpec.describe Committer::Commands::OutputMessage do
  let(:diff) { 'sample diff content' }
  let(:commit_context) { 'Test commit context' }
  let(:commit_message) { { summary: 'feat: add new feature', body: 'This is the commit body' } }
  let(:commit_generator) { instance_double(Committer::CommitGenerator) }

  describe '.execute' do
    before do
      allow(Committer::CommitGenerator).to receive(:check_git_status).and_return(diff)
      allow(Committer::CommitGenerator).to receive(:new).with(diff, commit_context).and_return(commit_generator)
      allow(commit_generator).to receive(:prepare_commit_message).and_return(commit_message)
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:exit)
    end

    it 'outputs the commit message summary and body' do
      expected_output = <<~OUTPUT
        #{commit_message[:summary]}

        #{commit_message[:body]}
      OUTPUT

      expect(described_class).to receive(:puts).with(expected_output)
      expect(described_class).to receive(:exit).with(0)

      described_class.execute([commit_context])
    end

    context 'when there is no body' do
      let(:commit_message) { { summary: 'feat: add new feature', body: nil } }

      it 'outputs only the summary' do
        expected_output = <<~OUTPUT
          #{commit_message[:summary]}


        OUTPUT

        expect(described_class).to receive(:puts).with(expected_output)
        expect(described_class).to receive(:exit).with(0)

        described_class.execute([commit_context])
      end
    end

    context 'when an error occurs' do
      before do
        allow(Committer::CommitGenerator).to receive(:check_git_status).and_raise(StandardError.new('Test error'))
      end

      it 'shows the error message and exits' do
        expect(described_class).to receive(:puts).with('Error: Test error')
        expect(described_class).to receive(:exit).with(1)

        described_class.execute([commit_context])
      end

      it 'handles any StandardError' do
        expected_error = StandardError.new('Config error')
        allow(Committer::CommitGenerator).to receive(:check_git_status).and_raise(expected_error)
        expect(described_class).to receive(:puts).with('Error: Config error')
        expect(described_class).to receive(:exit).with(1)

        described_class.execute([commit_context])
      end
    end
  end
end
