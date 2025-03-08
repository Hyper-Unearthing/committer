# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tempfile'
require 'committer/config/writer'

RSpec.describe Committer::Config::Writer do
  let(:temp_home) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_home, '.committer') }
  let(:config_file) { File.join(config_dir, 'config.yml') }

  before do
    # Stub Dir.home to return our temporary directory
    allow(Dir).to receive(:home).and_return(temp_home)

    # Set up constants in Committer::Config to use our temp paths
    stub_const('Committer::Config::Accessor::CONFIG_DIR', config_dir)
    stub_const('Committer::Config::Accessor::CONFIG_FILE', config_file)
    stub_const('Committer::Config::Writer::CONFIG_DIR', config_dir)
    stub_const('Committer::Config::Writer::CONFIG_FILE', config_file)
  end

  after do
    FileUtils.remove_entry(temp_home) if File.directory?(temp_home)
  end

  describe '.setup' do
    it 'calls create_default_config' do
      expect(described_class).to receive(:create_default_config).and_call_original
      described_class.setup
    end

    it 'outputs setup instructions' do
      expect { described_class.setup }.to output(/Created config file/).to_stdout
    end

    it 'writes config file' do
      expect(File.exist?(config_file)).to be false
      described_class.setup
      expect(File.exist?(config_file)).to be true
      config = YAML.load_file(config_file)
      expect(config).to eq(Committer::Config::Accessor::DEFAULT_CONFIG)
    end
  end

  describe '.create_default_config' do
    it 'creates the config directory' do
      expect(Dir.exist?(config_dir)).to be false
      described_class.create_default_config
      expect(Dir.exist?(config_dir)).to be true
    end

    it 'writes the config file if it does not exist' do
      expect(File.exist?(config_file)).to be false
      described_class.create_default_config
      expect(File.exist?(config_file)).to be true
    end

    it 'skips writing if the config file already exists' do
      # First create the file with test content
      FileUtils.mkdir_p(config_dir)
      test_content = { test: 'existing_content' }
      File.write(config_file, test_content.to_yaml)

      # Then try to create the default config
      expect { described_class.create_default_config }.to output(/skipping write/).to_stdout

      # Verify the file wasn't overwritten by checking it still contains our test value
      config = YAML.load_file(config_file)
      expect(config[:test]).to eq('existing_content')
    end
  end
end
