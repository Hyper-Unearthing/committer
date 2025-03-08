# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tempfile'

RSpec.describe Committer::Config::Accessor do
  let(:temp_home) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_home, '.committer') }
  let(:config_file) { File.join(config_dir, 'config.yml') }
  let(:git_root) { Dir.mktmpdir }
  let(:git_config_dir) { File.join(git_root, '.committer') }
  let(:git_config_file) { File.join(git_config_dir, 'config.yml') }
  let(:config_instance) { described_class.instance }

  before do
    # Reset the singleton before each test
    Singleton.__init__(described_class)

    # Stub Dir.home to return our temporary directory
    allow(Dir).to receive(:home).and_return(temp_home)

    # Set up constants in Committer::Config::Constants to use our temp paths
    stub_const('Committer::Config::Constants::CONFIG_DIR', config_dir)
    stub_const('Committer::Config::Constants::CONFIG_FILE', config_file)

    # Mock git root detection
    allow_any_instance_of(described_class).to receive(:`)
      .with('git rev-parse --show-toplevel')
      .and_return("#{git_root}\n")
  end

  after do
    FileUtils.remove_entry(temp_home) if File.directory?(temp_home)
    FileUtils.remove_entry(git_root) if File.directory?(git_root)
  end

  context 'when no config files exist' do
    it 'raises not setup error' do
      expect { config_instance }.to raise_error(Committer::ConfigErrors::NotSetup)
    end
  end

  context 'when only home config file exists' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, { 'api_key' => 'home_key', 'model' => 'home_model', 'scopes' => ['home'] }.to_yaml)
    end

    it 'loads config from home file' do
      expect(config_instance['api_key']).to eq('home_key')
      expect(config_instance['model']).to eq('home_model')
      expect(config_instance['scopes']).to eq(['home'])
    end

    it 'returns full config with to_h' do
      expect(config_instance.to_h).to include({ 'api_key' => 'home_key', 'model' => 'home_model',
                                                'scopes' => ['home'] })
    end
  end

  context 'when only git root config file exists' do
    before do
      FileUtils.mkdir_p(git_config_dir)
      File.write(git_config_file, { 'api_key' => 'git_key', 'model' => 'git_model', 'scopes' => ['git'] }.to_yaml)
    end

    it 'loads config from git root file' do
      expect(config_instance['api_key']).to eq('git_key')
      expect(config_instance['model']).to eq('git_model')
      expect(config_instance['scopes']).to eq(['git'])
    end
  end

  context 'when both config files exist' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, { 'api_key' => 'home_key', 'model' => 'home_model', 'scopes' => ['home'] }.to_yaml)

      FileUtils.mkdir_p(git_config_dir)
      File.write(git_config_file, { 'api_key' => 'git_key', 'model' => 'git_model' }.to_yaml)
    end

    it 'merges configs with git root taking precedence' do
      expect(config_instance['api_key']).to eq('git_key')
      expect(config_instance['model']).to eq('git_model')
      expect(config_instance['scopes']).to eq(['home'])
    end
  end

  context 'when config file is invalid' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, 'invalid:yaml:[}')

      # Make sure YAML.load_file raises an exception for the home config
      allow(YAML).to receive(:load_file).with(config_file).and_raise(
        Psych::SyntaxError.new('file', 0, 0, 0, 'invalid syntax', 'problem')
      )
      # But allow normal behavior for other files
      allow(YAML).to receive(:load_file).and_call_original
    end

    it 'continues execution and uses default config' do
      expect { config_instance }.to raise_error(Committer::ConfigErrors::FormatError)
    end
  end

  context 'when git root detection fails' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, { 'api_key' => 'home_key', 'model' => 'home_model' }.to_yaml)

      allow_any_instance_of(described_class).to receive(:`)
        .with('git rev-parse --show-toplevel')
        .and_raise(StandardError.new('git error'))
    end

    it 'falls back to home config' do
      expect(config_instance['api_key']).to eq('home_key')
      expect(config_instance['model']).to eq('home_model')
    end
  end

  context 'when git repository is not found' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, { 'api_key' => 'home_key', 'model' => 'home_model' }.to_yaml)

      allow_any_instance_of(described_class).to receive(:`).with('git rev-parse --show-toplevel').and_return('')
    end

    it 'falls back to home config' do
      expect(config_instance['api_key']).to eq('home_key')
      expect(config_instance['model']).to eq('home_model')
    end
  end

  describe 'memoization and reloading' do
    before do
      FileUtils.mkdir_p(config_dir)
      File.write(config_file, { 'api_key' => 'initial_key' }.to_yaml)
      # Force initialization
      config_instance
    end

    it 'memoizes config values' do
      # Update the file but don't reload
      File.write(config_file, { 'api_key' => 'updated_key' }.to_yaml)

      # Should still have old value
      expect(config_instance['api_key']).to eq('initial_key')
    end

    it 'reloads config when explicitly told to' do
      # Update the file
      File.write(config_file, { 'api_key' => 'reloaded_key' }.to_yaml)

      # Reload and check
      config_instance.reload
      expect(config_instance['api_key']).to eq('reloaded_key')
    end
  end
end
