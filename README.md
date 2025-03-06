# Committer

An AI-powered git commit message generator using Claude.

## Overview

The goal of committer is to make it easier to write beautiful commits.

Committer uses Claude AI to analyze your staged git changes and generate conventional commit messages for you. It detects the type of changes (feature, fix, refactor, etc.) and creates a well-formatted commit message that follows best practices.

## What Makes a Good Commit

A good commit should:

- Have a summary that clearly describes the change
- Explain WHY the change was made, not just what changed

When a future developer uses git blame to understand a line of code, they should immediately understand why the change was made. This context is invaluable for maintaining and evolving the codebase effectively.

## How Committer Helps

Committer analyzes your code changes and generates commit messages that:

1. Provide a clean, descriptive summary of the change
2. Include context about why the change was necessary
3. Follow conventional commit format for consistency

## Installation

### Install from RubyGems

```bash
gem install committer
```

## Configuration

Before using Committer, you need to set up your configuration file:

```bash
committer setup
```

This will create a template config file at `~/.committer/config.yml`.

Next, edit this file to add your Anthropic API key and optionally change the model or configure commit scopes:

```yaml
api_key: your_anthropic_api_key_here
model: claude-3-7-sonnet-20250219
scopes:
  - feature
  - api
  - ui
```

The `scopes` configuration is optional. When provided, Committer will generate conventional commit messages with scopes (like `feat(api): add new endpoint`). If left as `null` or omitted, commit messages will be generated without scopes (like `feat: add new endpoint`).

You only need to do this setup once.

## Usage

When you have changes staged in git (after running `git add`), simply run:

```bash
committer
```

This will:

1. Get the diff of your staged changes
2. Ask you for optional context about why you're making the change
3. Send the diff and context to Claude for analysis
4. Generate a commit message in conventional format (with scope if configured)
5. Open your default git editor with the suggested message
6. Allow you to edit the message if needed or simply save to confirm

## Commands

- `committer` - Generate commit message for staged changes
- `committer setup` - Create the config file template
- `committer help` - Display help information

## License

MIT
