# frozen_string_literal: true

require 'spec_helper'
require 'committer/git_helper'

RSpec.describe Committer::GitHelper do
  describe '.repo_root' do
    it 'returns the git repo root' do
      allow(Committer::GitHelper).to receive(:`).with('git rev-parse --show-toplevel').and_return("/path/to/repo\n")
      expect(Committer::GitHelper.repo_root).to eq('/path/to/repo')
    end
  end

  describe '.staged_diff' do
    it 'returns the git diff output' do
      allow(Open3).to receive(:capture3).with('git diff --staged').and_return(['diff output', '',
                                                                               double(success?: true)])
      expect(Committer::GitHelper.staged_diff).to eq('diff output')
    end

    it 'raises an error if git diff fails' do
      allow(Open3).to receive(:capture3).with('git diff --staged').and_return(['', 'error message',
                                                                               double(success?: false)])
      expect do
        Committer::GitHelper.staged_diff
      end.to raise_error(Committer::Error, 'Failed to get git diff: error message')
    end
  end

  describe '.commit' do
    it 'commits with summary only' do
      expect(Committer::GitHelper).to receive(:system).with('git', 'commit', '-m', 'test summary', '-e')
      Committer::GitHelper.commit('test summary')
    end

    it 'commits with summary and body' do
      expect(Committer::GitHelper).to receive(:system).with('git', 'commit', '-m', 'test summary', '-m', 'test body',
                                                            '-e')
      Committer::GitHelper.commit('test summary', 'test body')
    end
  end
end
