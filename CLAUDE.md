# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DotRun (`dr`) is a unified Bash script management framework that provides instant access to custom scripts, aliases, and configurations from anywhere. It supports Bash, Zsh, and Fish shells.

**Version:** 3.1.1

## Development Setup

```bash
# Clone and set up development environment
./dev.sh
```

This creates symlinks from `~/.local/share/dotrun` to `core/shared/dotrun/`, enabling live testing without reinstallation.

## Common Commands

```bash
# Linting (ShellCheck is required)
shellcheck core/shared/dotrun/dr
find core/shared/dotrun -name "*.sh" -exec shellcheck {} +

# Test core workflows manually
dr set test-script    # Create script
dr test-script        # Run script
dr -L                 # List with docs
dr -a set test        # Create alias file
dr -c set test        # Create config file
dr -col list          # List collections
dr reload             # Reload shell config (applies alias/config changes)
dr upgrade --check    # Check for updates
dr upgrade            # Upgrade to latest version
```

## Architecture

### Directory Structure

```
core/
├── shared/dotrun/           # Core tool files (symlinked during dev/install)
│   ├── dr                   # Main executable (~45k LOC Bash)
│   ├── .dr_config_loader    # Shell config loader
│   ├── core/                # Feature modules
│   │   ├── aliases.sh       # Alias management system
│   │   ├── collections.sh   # Collection import/sync system
│   │   ├── config.sh        # Config/env var management
│   │   ├── upgrade.sh       # Self-update from GitHub releases
│   │   ├── templates/       # Script templates
│   │   └── help-messages/   # CLI help text by feature
│   │       ├── core/
│   │       │   ├── help-message.sh      # Main dr --help output
│   │       │   ├── no-command.sh        # dr (no command provided)
│   │       │   └── reload.sh            # dr -r / dr reload
│   │       ├── scripts/
│   │       │   ├── move.sh              # dr -s move (without args)
│   │       │   └── no-args.sh           # dr -s / dr scripts (no subcommand)
│   │       ├── aliases/
│   │       │   ├── init.sh              # dr -a init (initialization success)
│   │       │   ├── move.sh              # dr -a move (without args)
│   │       │   ├── no-args.sh           # dr -a / dr aliases (no subcommand)
│   │       │   └── set.sh               # dr -a set (without args)
│   │       ├── configs/
│   │       │   ├── move.sh              # dr -c move (without args)
│   │       │   ├── no-args.sh           # dr -c / dr config (no subcommand)
│   │       │   └── set.sh               # dr -c set (without args)
│   │       ├── collections/
│   │       │   ├── help-message.sh      # dr -col --help (detailed guide)
│   │       │   ├── no-args.sh           # dr -col (no subcommand)
│   │       │   ├── remove.sh            # dr -col remove (without args)
│   │       │   ├── init-success.sh      # dr -col init (success message)
│   │       │   ├── conflict-menu.sh     # Interactive conflict resolution menu
│   │       │   ├── import-menu.sh       # Resource selection menu (a/s/l/h/c/n)
│   │       │   ├── invalid-url.sh       # GitHub URL validation error
│   │       │   └── errors/              # Error handling scripts
│   │       │       ├── git-errors.sh    # Git operation errors (5 types)
│   │       │       └── file-errors.sh   # File operation errors (9 types)
│   │       ├── upgrade/
│   │       │   ├── no-args.sh           # dr upgrade (usage/help)
│   │       │   ├── check-result.sh      # dr upgrade --check (result display)
│   │       │   └── errors/              # Upgrade error handling scripts
│   │       │       └── network-errors.sh # Network errors (3 types)
│   │       └── helpers/
│   │           └── loadHelpers-usage.sh # loadHelpers function usage
│   ├── helpers/             # Shared helper functions
│   │   ├── constants.sh            # Shared constants (icons, colors, paths)
│   │   ├── list_feature_files_tree.sh  # Unified tree display for features
│   │   ├── lint.sh                 # Linting helpers
│   │   └── loadHelpers.sh          # Helper loader
│   └── shell/               # Shell-specific integration
│       ├── bash/            # Bash completion + init
│       ├── zsh/             # Zsh completion + init
│       └── fish/            # Fish completion + init
└── config/dotrun/           # Example scripts/aliases/configs
```

### User Workspace (`~/.config/dotrun/`)

```
scripts/    # User scripts (*.sh)
aliases/    # Alias files (*.aliases) - multiple aliases per file
configs/    # Config files (*.config) - environment variables/exports
helpers/    # User helper functions (*.sh)
```

### Installed Location (`~/.local/share/dotrun/`)

Contains symlinks (dev) or copies (production) of `core/shared/dotrun/` contents.

## Core Concepts

### Script Documentation Format

Scripts use `### DOC` blocks for self-documentation:

```bash
#!/usr/bin/env bash
### DOC
# Brief description (shown in dr -L)
### DOC
#
# Extended docs (shown in dr help <name>)
#
### DOC

set -euo pipefail

main() {
    # Script logic
}

main "$@"
```

### Namespace Shortcuts

- `dr -s` / `dr scripts` - Script management
- `dr -a` / `dr aliases` - Alias file management
- `dr -c` / `dr config` - Config file management
- `dr -col` / `dr collections` - Collection management
- `dr upgrade` - Self-update from GitHub releases

### Collections System

Collections are Git repositories containing shareable scripts/aliases/configs. When installed, resources are copied with hash tracking for smart updates and conflict resolution.

## Shell Script Conventions

- Use `set -euo pipefail` at script start
- Quote all variables: `"$variable"`
- Functions: `lowercase_with_underscores()`
- Constants: `UPPERCASE_CONSTANTS` or `USER_PREFIXED_VARS` for environment variables
- Always check command existence before use
- Handle errors explicitly with meaningful messages to stderr
- Use `local` for function-scoped variables
- Standard environment variables: `USER_COLLECTION_ALIASES`, `USER_COLLECTION_CONFIGS`, `USER_COLLECTION_SCRIPTS`
- Shared path constants: `SHARED_DR_PATH`, `SHARED_DR_CORE_PATH`, `SHARED_DR_HELPERS_PATH` (defined in `dr` main file)
- Source `constants.sh` for consistent icons, colors, and paths across features
- Use helper functions: `get_feature_dir`, `get_feature_icon`, `get_feature_color`, `get_feature_ext`
- Delegate tree display to `list_feature_files_tree.sh` (unified implementation)
- Lazy-load feature modules: Use `_load_*_module()` pattern to source core/\*.sh files only when needed
- **Error handling pattern**: Use `exec` or `source` to call external help scripts instead of inline echo statements
  - **Performance benefit**: Moves help text out of function bodies, reducing memory footprint and improving load times
  - `exec` for terminal messages (replaces current process, exits after display):
    - Used when no further processing needed after showing help
    - Example: `exec "${BASH_SOURCE[0]%/core/*}/core/help-messages/aliases/init.sh" "$USER_COLLECTION_ALIASES"`
    - Example: `exec "${BASH_SOURCE[0]%/core/*}/core/help-messages/aliases/set.sh"`
  - `source` for inline messages (script continues after message):
    - Used for error conditions within larger functions
    - Example: `source "${BASH_SOURCE[0]%/core/*}/core/help-messages/collections/errors/git-errors.sh" "clone-timeout-30" "$url"`
  - Help scripts accept dynamic variables as parameters for contextual error messages
  - Path resolution pattern: `"${BASH_SOURCE[0]%/core/*}/core/help-messages/..."` (strips `/core/*` suffix to get repo root)
- **Collections error handling**: Use parameterized error scripts for structured troubleshooting
  - Git errors: `git-errors.sh <error-type> [vars...]` - handles clone timeouts, repo access, fetch failures
  - File errors: `file-errors.sh <error-type> [vars...]` - handles metadata, permissions, copy failures
  - Interactive menus: `conflict-menu.sh`, `import-menu.sh`, `invalid-url.sh` for user prompts and validation errors
- **Upgrade error handling**: Network-related errors for self-update functionality
  - Network errors: `network-errors.sh <error-type>` - handles API failures, install failures, missing downloaders (3 types)

### Help Message Script Pattern

Help message scripts in `core/help-messages/` follow a consistent structure:

**Basic help message (usage/commands):**

```bash
#!/usr/bin/env bash
# Help message for: <description>

# Color codes (standard set)
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

FEATURE_COLOR="${COLOR}"  # Feature-specific: GREEN=scripts, PURPLE=aliases, RED=configs, BLUE=collections

cat <<EOF
${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}...${RESET}
${GRAY}Commands:${RESET}
  ...
${GRAY}Examples:${RESET}
  ...
EOF
```

**Parameterized error message (accepts dynamic variables):**

```bash
#!/usr/bin/env bash
# Help messages for: <error category>
# Usage: script.sh <error-type> [dynamic-vars...]

# Color codes
BOLD=$'\e[1m'
CYAN=$'\e[36m'
# ... (same as above)

error_type="${1:-}"
shift

case "$error_type" in
  clone-timeout-30)
    url="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Clone operation timed out
${GRAY}URL:${RESET} ${YELLOW}$url${RESET}
${GRAY}Troubleshooting:${RESET}
  1. Check internet connection
  2. Try: ${CYAN}dr -col add ~/temp-clone${RESET}
EOF
    ;;
  # ... more error types
esac
```

**Color Conventions:**

- `GREEN` - Scripts feature (`dr -s`)
- `PURPLE` - Aliases feature (`dr -a`)
- `RED` - Configs feature (`dr -c`)
- `BLUE` - Collections feature (`dr -col`)
- `CYAN` - Command name (`dr`)
- `YELLOW` - User input placeholders (`<name>`, `<source>`, etc.)
- `GRAY` - Section headers (Usage, Commands, Examples) and inline comments

## Key Files

| File                                                    | Purpose                                            |
| ------------------------------------------------------- | -------------------------------------------------- |
| `core/shared/dotrun/dr`                                 | Main executable - CLI parser, lazy module loading  |
| `core/shared/dotrun/core/scripts.sh`                    | Script management module (lazy-loaded)             |
| `core/shared/dotrun/core/collections.sh`                | Collection add/sync/update (~113k LOC)             |
| `core/shared/dotrun/core/aliases.sh`                    | Alias file management (file-based, lazy-loaded)    |
| `core/shared/dotrun/core/config.sh`                     | Config/export management (file-based, lazy-loaded) |
| `core/shared/dotrun/core/upgrade.sh`                    | Self-update system (lazy-loaded, GitHub releases)  |
| `core/shared/dotrun/helpers/constants.sh`               | Shared constants (icons, colors, paths)            |
| `core/shared/dotrun/helpers/list_feature_files_tree.sh` | Unified tree display for all features              |
| `core/shared/dotrun/helpers/lint.sh`                    | Linting helpers (sourced eagerly)                  |
| `install.sh`                                            | Production installer                               |
| `dev.sh`                                                | Development symlink setup                          |

## AI Skill

The `skills/dr-cli/` directory contains an AI agent skill for Claude Code and other agents. See `skills/dr-cli/SKILL.md` for trigger keywords and decision routing.
