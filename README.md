# Committer

An AI-powered git commit message generator using Claude.

## Overview

The goal of committer is to make it easier to write beautiful commits.

Committer uses Claude AI to analyze your staged git changes and generate [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) messages for you. It detects the type of changes (feature, fix, refactor, etc.) and creates a well-formatted commit message that follows best practices.

## What Makes a Good Commit

A good commit should:

- Have a summary that clearly describes the change
- Explain WHY the change was made, not just what changed

When a future developer uses git blame to understand a line of code, they should immediately understand why the change was made. This context is invaluable for maintaining and evolving the codebase effectively.

## How Committer Helps

Committer analyzes your code changes and generates commit messages that:

1. Provide a clean, descriptive summary of the change
2. Include context about why the change was necessary
3. Follow [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) format for consistency

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

The `scopes` configuration is optional. When provided, Committer will generate [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) messages with scopes (like `feat(api): add new endpoint`). If left as `null` or omitted, commit messages will be generated without scopes (like `feat: add new endpoint`).

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
4. Generate a commit message in [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) format (with scope if configured)
5. Open your default git editor with the suggested message
6. Allow you to edit the message if needed or simply save to confirm

## Commands

- `committer` - Generate commit message for staged changes
- `committer setup` - Create the config file template
- `committer help` - Display help information
- `committer setup-git-hook` - Install the git hook for automatic commit message generation
- `committer output-message` - Generate a commit message (used by the git hook)

## Git Hook Integration

Committer can be integrated directly with Git using a prepare-commit-msg hook, which automatically generates commit messages whenever you commit.

### Installing the Git Hook

To install the git hook, navigate to the root of your git repository and run:

```bash
committer setup-git-hook
```

This command will:

1. Verify you're in the root of a git repository
2. Install the prepare-commit-msg hook in your `.git/hooks` directory
3. Make the hook executable

### How the Git Hook Works

Once installed, the git hook will:

1. Automatically run whenever you execute `git commit`
2. Generate an AI-powered commit message based on your staged changes
3. Pre-fill your commit message editor with the generated message
4. Allow you to edit the message before finalizing the commit

Since git hooks run in non-interactive mode, you can provide context for your commit by using the REASON environment variable:

```bash
REASON="Improve performance by optimizing database queries" git commit
```

If you don't provide a REASON, the commit message will still be generated, but without the additional context that would be used to generate a more detailed body.

## Development

### Running Tests

Committer uses RSpec for testing. To run the tests:

```bash
bundle install
bundle exec rake spec
```

## Evaluation Tools

The `eval` directory contains tools for benchmarking and testing commit message generation across different AI models. These tools help evaluate the quality and consistency of generated commit messages.

### Usage

1. **Install dependencies**:

   ```bash
   npm install
   npm install -g promptfoo
   ```

2. **Set environment variables**:

   ```bash
   export ANTHROPIC_API_KEY=your_anthropic_api_key_here
   export OPENAI_API_KEY=your_openai_api_key_here
   ```

3. **Dump commits** from a repository to a database:

   ```bash
   node eval.mjs dump-commits --eval-data-dir ./path --repo ./repo-path
   ```

4. **Process commits** for evaluation:

   ```bash
   node eval.mjs process-commits --eval-data-dir ./path
   ```

5. **Run evaluations** against different AI models:
   ```bash
   node eval.mjs run-evaluation --eval-data-dir ./path [--sha commit_sha] [--limit number]
   ```

The system compares multiple AI models (Claude 3.7 Sonnet, Claude 3.5 Haiku, GPT-4o, GPT-4o Mini) and tests their ability to generate properly formatted conventional commit messages based on commit diffs.

### Viewing Evaluation Results prompt versions

select your verison from https://drive.google.com/drive/folders/1xHpOkNSss2PM-cnLKGaCHLNfWvxl9hAX

download .promptfoo file and move it to ~/.promptfoo promptfoo.sqlite

```bash
npm install -g promptfoo
promptfoo view -y
```

### Running Evaluation for prompt versions

select your verison from https://drive.google.com/drive/folders/1xHpOkNSss2PM-cnLKGaCHLNfWvxl9hAX

download .electron-eval folder and move it the root fo this project

```bash
npm install
npm install -g promptfoo
export ANTHROPIC_API_KEY=your_anthropic_api_key_here
export OPENAI_API_KEY=your_openai_api_key_here
node eval.mjs run-evaluation --eval-data-dir ./electron-eval
```

## License

MIT
