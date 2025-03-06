# frozen_string_literal: true

require_relative 'lib/committer/version'

Gem::Specification.new do |spec|
  spec.name = 'committer'
  spec.version = Committer::VERSION
  spec.authors = ['Sebastien Stettler']
  spec.email = ['sebastien@managerbot.dev']

  spec.summary = 'AI-powered git commit message generator using Claude'
  spec.description = 'A tool that uses Claude API to generate conventional commit messages based on staged changes'
  spec.homepage = 'https://github.com/Hyper-Unearthing/committer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.files = Dir['lib/**/*', 'bin/*', 'README.md', 'LICENSE.txt']
  spec.bindir = 'bin'
  spec.executables = %w[committer]
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty', '~> 0.20'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
