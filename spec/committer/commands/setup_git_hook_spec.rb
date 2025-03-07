# frozen_string_literal: true

require 'spec_helper'
require 'committer/commands/setup_git_hook'

RSpec.describe Committer::Commands::SetupGitHook do
  describe '.execute' do
    context 'when not in a git repository' do
      before do
        allow(Dir).to receive(:exist?).with('.git').and_return(false)
        allow($stdout).to receive(:puts)
      end

      it 'exits with status code 1' do
        expect { described_class.execute([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs an error message' do
        expect($stdout).to receive(:puts).with('Error: Current directory is not a git repository.')

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end
    end

    context 'when not at the root of a git repository' do
      before do
        allow(Dir).to receive(:exist?).with('.git').and_return(true)
        allow(described_class).to receive(:`).with('git rev-parse --show-toplevel').and_return("/different/path\n")
        allow(Dir).to receive(:pwd).and_return('/current/path')
        allow($stdout).to receive(:puts)
      end

      it 'exits with status code 1' do
        expect { described_class.execute([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs an error message' do
        expect($stdout).to receive(:puts).with('Error: Please run this command from the root of your git repository.')

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end
    end

    context 'when hook file already exists' do
      before do
        allow(Dir).to receive(:exist?).with('.git').and_return(true)
        allow(described_class).to receive(:`).with('git rev-parse --show-toplevel').and_return("#{Dir.pwd}\n")
        allow(Dir).to receive(:pwd).and_return(Dir.pwd)
        allow(File).to receive(:exist?).with('.git/hooks/prepare-commit-msg').and_return(true)
        allow($stdout).to receive(:puts)
      end

      it 'exits with status code 1' do
        expect { described_class.execute([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs an error message' do
        expect($stdout).to receive(:puts).with('Error: prepare-commit-msg hook already exists.')
        expect($stdout).to receive(:puts).with('Please remove or rename the existing hook and try again.')

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end
    end

    context 'when installation succeeds' do
      let(:hook_path) { '.git/hooks/prepare-commit-msg' }
      let(:template_path) { File.expand_path('../prepare-commit-msg', File.dirname(__dir__)) }
      let(:hook_content) { '#!/bin/sh\n# Test hook content' }

      before do
        allow(Dir).to receive(:exist?).with('.git').and_return(true)
        allow(described_class).to receive(:`).with('git rev-parse --show-toplevel').and_return("#{Dir.pwd}\n")
        allow(Dir).to receive(:pwd).and_return(Dir.pwd)
        allow(File).to receive(:exist?).with(hook_path).and_return(false)
        allow(File).to receive(:expand_path).with('../prepare-commit-msg', anything).and_return(template_path)
        allow(File).to receive(:read).with(template_path).and_return(hook_content)
        allow(File).to receive(:write)
        allow(File).to receive(:chmod)
        allow($stdout).to receive(:puts)
      end

      it 'reads the hook template file' do
        expect(File).to receive(:read).with(template_path).and_return(hook_content)

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end

      it 'writes the hook file with the template content' do
        expect(File).to receive(:write).with(hook_path, hook_content)

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end

      it 'makes the hook file executable' do
        expect(File).to receive(:chmod).with(0o755, hook_path)

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end

      it 'outputs success message' do
        expect($stdout).to receive(:puts).with('Git hook successfully installed!')
        expect($stdout).to receive(:puts).with('Now your commit messages will be automatically generated.')

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end

      it 'exits with status code 0' do
        expect { described_class.execute([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(Dir).to receive(:exist?).with('.git').and_return(true)
        allow(described_class).to receive(:`).with('git rev-parse --show-toplevel').and_return("#{Dir.pwd}\n")
        allow(Dir).to receive(:pwd).and_return(Dir.pwd)
        allow(File).to receive(:exist?).with('.git/hooks/prepare-commit-msg').and_return(false)
        allow(File).to receive(:expand_path).with('../prepare-commit-msg', anything).and_return('/path/to/template')
        allow(File).to receive(:read).and_raise(StandardError.new('Test error'))
        allow($stdout).to receive(:puts)
      end

      it 'exits with status code 1' do
        expect { described_class.execute([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs an error message' do
        expect($stdout).to receive(:puts).with('Error: Test error')

        begin
          described_class.execute([])
        rescue SystemExit
          # Expected
        end
      end
    end
  end
end
