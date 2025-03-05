# Committer

An AI-powered git commit message generator using Claude.

## Overview

Committer uses Claude AI to analyze your staged git changes and generate conventional commit messages for you. It detects the type of changes (feature, fix, refactor, etc.) and creates a well-formatted commit message that follows best practices.

## Installation

### Install from RubyGems

```bash
gem install committer
```

### Manual Installation

1. Install Bundler if you haven't already:

   ```sh
   gem install bundler
   ```

2. Install the project dependencies:
   ```sh
   bundle install
   ```

3. Link the executable:
   ```bash
   gem build committer.gemspec
   gem install committer-0.1.0.gem
   ```

## Configuration

Before using Committer, you need to set up your configuration file:

```bash
committer setup
```

This will create a template config file at `~/.committer/config.yml`.

Next, edit this file to add your Anthropic API key and optionally change the model:

```yaml
api_key: your_anthropic_api_key_here
model: claude-3-sonnet-20240229
```

You only need to do this setup once.

## Usage

When you have changes staged in git (after running `git add`), simply run:

```bash
committer
```

This will:
1. Get the diff of your staged changes
2. Send it to Claude for analysis
3. Generate a commit message in conventional format
4. Open your default git editor with the suggested message
5. Allow you to edit the message if needed or simply save to confirm

## Commands

- `committer` - Generate commit message for staged changes
- `committer setup` - Create the config file template
- `committer help` - Display help information

You can also run it directly through git:

```bash
git smart-commit
```

## License

MIT
