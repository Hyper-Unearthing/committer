# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Require the necessary files
require 'committer/config'
require 'committer/prompt_templates'
require 'committer/commit_generator'
require 'clients/claude_client'

# Helper methods for tests
module SpecHelpers
  def fixture_path(filename)
    File.join(File.expand_path('fixtures', __dir__), filename)
  end

  def load_fixture(filename)
    File.read(fixture_path(filename))
  end
end

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Enable the expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up any test-specific files after tests run
  config.after(:suite) do
    # Add cleanup code here if needed
  end

  # Include SpecHelpers in all spec files
  config.include SpecHelpers
end
