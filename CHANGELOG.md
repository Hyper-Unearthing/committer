Changelog
---------

Auto-generated from git commits.

HEAD   (2025-03-08 18:46:43 +0800)


v0.4.2   (2025-03-08 18:46:43 +0800)
  * bump version [5d4f365]
  * refactor: remove unused HTTParty dependency [826b7b9]

v0.4.1   (2025-03-08 18:40:41 +0800)
  * update changelog [8eb97a7]
  * bump version [0876d7f]
  * refactor: replace HTTParty with standard Ruby Net::HTTP [078cb0c]
  * update change log [9448513]

v0.4.0   (2025-03-08 18:18:20 +0800)
  * bump version [30fa939]
  * feat: add sample formatting rules file creation during setup [92b0e2b]
  * feat: add custom formatting rules loader for commit messages [20ac7ea]
  * fix: correct config file writing and improve message display [2409844]
  * refactor: extract Git operations to dedicated GitHelper class [f01afea]
  * refactor: extract config constants into separate module [5c368e5]
  * fix: prevent overwriting existing config file [8bda82a]
  * refactor: extract config writer to separate class [c709afb]
  * refactor: restructure configuration into a module with accessor class 
    [6e7d2f0]
  * fix: add missing stub for config loading in claude client specs [a931a00]
  * docs: add CHANGELOG.md and script for automatic generation [ba5aae1]
  * test: refactor specs to use more realistic test configurations [206b1ff]
  * refactor: convert Config to singleton with git repository support [51714f0]
  * refactor: restructure prompt generation system for better configurability 
    [566ba2e]
  * test: update commit prompt tests for consistency [a0ab163]
  * style: reorder gems alphabetically in Gemfile [f57585f]
  * fix: Fix scopes handling in CommitGenerator [cfdc63e]
  * chore: Add Pry gem for improved debugging in test environment [397c73a]
  * ignore release directory [bb6102b]

v0.3.2   (2025-03-07 13:48:19 +0800)
  * bump version [0000c85]
  * feat: add git hook integration for automatic commit message generation 
    [7d8ca65]
  * refactor: restructure command execution into separate files [6079dfb]
  * feat: add output-message subcommand to support git hooks [6474f73]
  * chore: add Rubocop gem to development dependencies [589d12f]
  * ci: add GitHub Actions workflows for Rubocop and RSpec tests [f07edc4]
  * test: add CommitGenerator specs with fixture data [183b1c9]
  * test: add Config class tests for handling configuration files [3cb7de8]
  * test: add ClaudeClient specs for initialization and API interaction 
    [2fe7ff8]
  * chore: setup testing infrastructure and update documentation [071e316]
  * refactor: Extract CommitGenerator class for better separation of concerns 
    [9d8a666]
  * style: disable Documentation cop in RuboCop configuration [1b8c783]
  * docs: add links to Conventional Commits specification [bdc54e4]
  * docs: remove incorrect manual installation instructions [c6fe711]

v0.2.2   (2025-03-06 14:50:19 +0800)
  * feat: bump gem version [030aef6]
  * fix: restore original executable name in gemspec [1a62ff4]
  * chore: remove git-smart-commit script and update gemspec [76b0e38]
  * docs: update README with committer's goals and new features [e5050bf]
  * remove note about smart commit [4c6e240]

v0.2.1   (2025-03-06 14:25:52 +0800)
  * cut release [0b1c7ff]
  * fix: Restore string interpolation syntax in prompt templates [9b2aa1b]
  * feat(model): update default model to claude-3-7-sonnet-20250219 [36b26d3]
  * feat: add optional scope configuration for commit messages [7dd1541]
  * feat(committer): separate prompt templates into module [9006230]
  * chore(deps): add rubocop config and fix all linting errors [8df00e7]
  * refactor(committer): enhance commit message generation with context 
    [c524a04]

v0.1.1   (2025-03-05 21:55:18 +0800)
  * bump version delete built gem [b12034f]

v0.1.0

