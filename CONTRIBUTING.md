# Contributing to DotRun

Thank you for your interest in contributing to DotRun! We appreciate your time and effort in helping make this unified script management framework better for everyone. Whether you're fixing a bug, improving documentation, or proposing a new feature, your contributions are valuable and welcomed.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Pull Request Process](#pull-request-process)
- [Commit Message Format](#commit-message-format)
- [Getting Help](#getting-help)

## Code of Conduct

By participating in this project, you agree to maintain a respectful, inclusive, and collaborative environment. We expect all contributors to:

- Be respectful and considerate in communication
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Ways to Contribute

There are many ways you can contribute to DotRun:

### Reporting Bugs

Found a bug? Help us fix it:

1. Check the [issue tracker](https://github.com/jvPalma/dotrun/issues) to see if it's already reported
2. If not, [open a new issue](https://github.com/jvPalma/dotrun/issues/new) with:
   - A clear, descriptive title
   - Steps to reproduce the issue
   - Expected behavior vs actual behavior
   - Your environment (OS, shell type, DotRun version)
   - Any relevant error messages or logs

### Suggesting Features

Have an idea for a new feature?

1. Check existing [issues](https://github.com/jvPalma/dotrun/issues) and [discussions](https://github.com/jvPalma/dotrun/discussions) first
2. Open a new issue with the "enhancement" label
3. Clearly describe the feature and its benefits
4. Explain your use case and why it would be valuable
5. Consider implementation approaches if you have ideas

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or clarify existing documentation
- Add examples and use cases
- Improve the [Wiki](https://github.com/jvPalma/dotrun/wiki)
- Write tutorials or guides
- Translate documentation (future support)

### Contributing Code

Ready to contribute code? Here's how:

1. Start with "good first issue" or "help wanted" labels
2. Comment on the issue to let others know you're working on it
3. Follow the development setup and guidelines below
4. Submit a pull request when ready

## Development Setup

### Prerequisites

- **Git**: For version control
- **Bash 4.0+**: Primary development shell
- **ShellCheck**: For linting (optional but recommended)
- A Unix-like environment (Linux, macOS, or WSL on Windows)

### Quick Setup

1. Fork the repository on GitHub

2. Clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/dotrun.git
   cd dotrun
   ```

3. Set up the development environment:

   ```bash
   ./dev.sh
   ```

   This script:
   - Creates symlinks from `~/.local/share/dotrun` to your repo's `core/shared/dotrun` directory
   - Allows you to test changes immediately without reinstallation
   - Preserves your existing DotRun installation and data

4. Add the upstream remote:

   ```bash
   git remote add upstream https://github.com/jvPalma/dotrun.git
   ```

5. Create a branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Project Structure

```
dotrun/
├── core/
│   ├── shared/dotrun/          # Core DotRun files
│   │   ├── dr                  # Main executable
│   │   ├── core/               # Core functionality modules
│   │   │   ├── *.sh            # Feature modules
│   │   │   └── templates/      # Script templates
│   │   ├── helpers/            # Shared helper functions
│   │   ├── shell/              # Shell integration
│   │   │   ├── bash/           # Bash-specific code
│   │   │   ├── zsh/            # Zsh-specific code
│   │   │   └── fish/           # Fish-specific code
│   │   └── VERSION             # Version file
│   └── config/dotrun/          # Example scripts and configs
├── install.sh                  # Installation script
├── dev.sh                      # Development setup script
└── README.md                   # Project documentation
```

### Development Workflow

1. Make your changes in the appropriate files
2. Test locally using `dr` commands (changes are live via symlinks)
3. Run ShellCheck on modified files (see Testing section)
4. Commit your changes with clear messages
5. Push to your fork and create a pull request

## Code Style Guidelines

### Shell Script Best Practices

DotRun follows industry-standard shell scripting conventions:

#### General Guidelines

- **Use ShellCheck**: All shell scripts must pass ShellCheck linting
- **POSIX Compatibility**: Write portable code when possible, but Bash 4.0+ features are allowed
- **Error Handling**: Use `set -euo pipefail` at the start of scripts
- **Quoting**: Always quote variables: `"$variable"` not `$variable`
- **Functions**: Use lowercase with underscores for function names: `my_function()`
- **Constants**: Use UPPERCASE for constants: `TOOL_DIR`, `VERSION`

#### Code Structure

```bash
#!/usr/bin/env bash
# Brief description of what this script does

set -euo pipefail

# Constants at the top
readonly CONSTANT_NAME="value"

# Function definitions
function_name() {
  local local_var="$1"
  # Function implementation
}

# Main execution
main() {
  # Main logic here
}

# Call main with all arguments
main "$@"
```

#### Naming Conventions

- **Variables**: `lowercase_with_underscores` or `UPPERCASE_CONSTANTS`
- **Functions**: `lowercase_with_underscores()`
- **Files**: lowercase with hyphens for multi-word names (`my-script.sh`)

#### Comments and Documentation

- Add comments for non-obvious logic
- Use `### DOC` blocks for script documentation
- Explain "why" not "what" when the code is self-explanatory
- Keep comments up-to-date with code changes

Example documentation block:

```bash
### DOC
# Description: Brief description of what the script does
#
# Usage: dr scriptname [options] [arguments]
#
# Examples:
#   dr scriptname --option value
#   dr scriptname argument
#
# Options:
#   --help    Show this help message
### DOC
```

#### Error Handling

```bash
# Check for required commands
if ! command -v required_command &> /dev/null; then
  echo "Error: required_command not found" >&2
  exit 1
fi

# Validate inputs
if [[ $# -lt 1 ]]; then
  echo "Error: Missing required argument" >&2
  return 1
fi

# Handle errors gracefully
if ! some_command; then
  echo "Warning: some_command failed, continuing..." >&2
fi
```

#### ShellCheck Compliance

Before submitting code, run ShellCheck:

```bash
# Check a single file
shellcheck path/to/script.sh

# Check all shell scripts in core
find core/shared/dotrun -name "*.sh" -exec shellcheck {} +

# Check the main dr executable
shellcheck core/shared/dotrun/dr
```

Common ShellCheck warnings to avoid:

- SC2086: Quote variables to prevent word splitting
- SC2181: Check exit code directly with `if my_command; then`
- SC2155: Declare and assign separately to avoid masking return values
- SC2164: Use `cd foo || exit` to handle cd failures

## Testing Your Changes

### Manual Testing

1. Run `./dev.sh` to set up the development environment
2. Test your changes using real DotRun commands:

   ```bash
   # Test script management
   dr set test-script
   dr test-script
   dr list

   # Test alias management
   dr -a set test-aliases
   dr -a list

   # Test collection features
   dr -col list
   ```

3. Test across different shells if modifying shell integration:

   ```bash
   # Test in bash
   bash -c "source ~/.bashrc && dr <your-command>"

   # Test in zsh (if available)
   zsh -c "source ~/.zshrc && dr <your-command>"
   ```

4. Test edge cases:
   - Empty inputs
   - Special characters in names
   - Non-existent resources
   - Permission issues

### Automated Testing

While we don't have a comprehensive test suite yet, you should:

1. Run ShellCheck on all modified files
2. Verify your changes don't break existing functionality
3. Test installation on a clean system if modifying `install.sh`

### Regression Testing

Before submitting:

1. Test core workflows:
   - Creating, editing, and running scripts
   - Managing aliases and configs
   - Collection operations (add, update, sync)
   - Tab completion functionality

2. Verify help and documentation:
   - `dr --help` shows correct information
   - `dr help <command>` works for affected commands
   - Documentation is accurate

## Pull Request Process

### Before Submitting

1. Ensure your code follows the style guidelines
2. Run ShellCheck on all modified shell scripts
3. Test your changes thoroughly (see Testing section)
4. Update documentation if needed
5. Keep commits focused and atomic
6. Rebase on latest `master` branch:
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

### Creating the Pull Request

1. Push your branch to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a pull request on GitHub with:
   - **Clear title**: Summarize the change in one line
   - **Description**: Explain what changed and why
   - **Related issues**: Link related issues with "Fixes #123" or "Relates to #456"
   - **Testing**: Describe how you tested the changes
   - **Screenshots**: Include if relevant (especially for UI changes)

### PR Template Example

```markdown
## Description

Brief description of what this PR does and why.

## Related Issues

Fixes #123
Relates to #456

## Changes

- List of changes made
- Another change
- One more change

## Testing

- [ ] Ran ShellCheck on modified files
- [ ] Tested manually with `dr` commands
- [ ] Tested across different shells (if applicable)
- [ ] Verified documentation is accurate

## Checklist

- [ ] Code follows project style guidelines
- [ ] Comments added for non-obvious logic
- [ ] Documentation updated (README, Wiki, etc.)
- [ ] No breaking changes (or documented if unavoidable)
```

### Review Process

- A maintainer will review your PR
- Address any feedback or requested changes
- Once approved, a maintainer will merge your PR
- Your contribution will be included in the next release

### After Your PR is Merged

- Delete your feature branch:

  ```bash
  git branch -d feature/your-feature-name
  git push origin --delete feature/your-feature-name
  ```

- Update your fork:
  ```bash
  git checkout master
  git fetch upstream
  git merge upstream/master
  git push origin master
  ```

## Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for clear, standardized commit messages.

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code changes that neither fix a bug nor add a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Changes to build process, tools, or dependencies

### Examples

```bash
# Simple feature
feat: add fuzzy search for script names

# Bug fix with scope
fix(completion): resolve tab completion in fish shell

# Breaking change
feat!: redesign alias management to use file-based approach

BREAKING CHANGE: Aliases are now managed in files rather than individual entries.
Users need to migrate existing aliases using the provided migration script.

# Documentation
docs: update installation guide with WSL instructions

# Refactoring
refactor(core): extract duplicate code into shared helper

# Multiple changes
feat: add collection sync command

- Add sync command to check for updates
- Show modified files in collections
- Add --dry-run flag for preview
```

### Guidelines

- Use present tense: "add feature" not "added feature"
- Use imperative mood: "move cursor to" not "moves cursor to"
- Keep the first line under 72 characters
- Separate subject from body with a blank line
- Wrap body at 72 characters
- Use body to explain what and why, not how

## Getting Help

Need help with your contribution?

### Resources

- **Documentation**: Check the [Wiki](https://github.com/jvPalma/dotrun/wiki) for detailed guides
- **FAQ**: See [frequently asked questions](https://github.com/jvPalma/dotrun/wiki/FAQ)
- **Examples**: Browse the `core/config/dotrun` directory for examples

### Ask Questions

- **Issues**: Open an issue with the "question" label
- **Discussions**: Use [GitHub Discussions](https://github.com/jvPalma/dotrun/discussions) for general questions
- **Pull Request**: Ask questions directly in your PR if stuck

### Contact

- **GitHub Issues**: https://github.com/jvPalma/dotrun/issues
- **Project Maintainer**: João Vieira Palma ([@jvPalma](https://github.com/jvPalma))

---

## License

By contributing to DotRun, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

**Thank you for contributing to DotRun! Your efforts help make script management better for developers everywhere.**
