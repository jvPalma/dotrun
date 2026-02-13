# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DotRun (`dr`) is a unified Bash script management framework that provides instant access to custom scripts, aliases, and configurations from anywhere. It supports Bash, Zsh, and Fish shells.

**Version:** 3.1.3

## Development Setup

```bash
# Clone and set up development environment
./dev.sh

# Get help on setup script
./dev.sh --help
```

The `dev.sh` script sets up a complete development environment with 7 steps:

1. Symlinks `dr` binary to `~/.local/share/dotrun/`
2. Symlinks `.dr_config_loader` for shell integration
3. Symlinks core feature modules (`core/*.sh`) and `help-messages/` directory tree
4. Symlinks helper utilities (`helpers/*.sh`)
5. Symlinks VERSION file
6. Symlinks shell integration files for Bash, Zsh, and Fish (with stale symlink cleanup)
7. Creates `~/.local/bin` directory for binary access

This creates symlinks from `~/.local/share/dotrun` to `core/shared/dotrun/`, enabling live testing without reinstallation. The script validates required files (`core/shared/dotrun/dr` and `core/shared/dotrun/` structure) before proceeding.

**v3.1.3 updates:**

- Symlinks entire `core/help-messages/` directory tree (replaces old file-by-file copying)
- Cleans stale symlinks in shell directories before creating new ones (removes dangling links from deleted source files)

**Logging design:** The script uses color-coded output functions (`info`, `success`, `warning`, `error`) with unicode indicators for clear progress tracking during development setup.

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

#### Example: GraphQL Request Tool (`scripts/work/.gqlRequest/`)

User scripts can include subdirectories with modular helper systems. Example structure:

```
scripts/work/.gqlRequest/
├── gqlRequest.conf       # Persistent user configuration
├── helpers/              # Modular helper functions
│   ├── _loader.sh        # Helper module loader (require dependency system)
│   ├── queries.sh        # GraphQL query management
│   ├── query_cli.sh      # Query CLI (query-add/query-list/query-which commands)
│   ├── request.sh        # HTTP request helpers
│   ├── response.sh       # Response processing
│   ├── config.sh         # Configuration management (getters with env > config > default priority)
│   ├── config_cli.sh     # Config CLI (get/set/list commands)
│   ├── settings.sh       # Settings file I/O (read/write gqlRequest.conf with comment preservation)
│   ├── context.sh        # Kubectl context caching (avoids redundant context switches)
│   ├── kube-context.sh   # Kubectl context switching (fully internalized - no external dependencies)
│   ├── tunnel.sh         # Port forwarding management
│   ├── variables.sh      # Variable parsing/merging
│   ├── watchdog.sh       # Process monitoring
│   ├── cli.sh            # CLI commands
│   └── ai_skill.sh       # AI skill symlink management (uses BASH_SOURCE for dynamic paths)
├── queries/              # External GraphQL query definitions (*.graphql)
│   ├── introspection.graphql
│   ├── echo.graphql
│   ├── userInfo.graphql
│   ├── me.graphql
│   ├── orgName.graphql
│   └── ...               # Additional query files
├── ai-skill-gql-request/ # AI agent skill for Claude Code integration
└── test_queries.sh       # Test suite for query module
```

**Key patterns:**

- External `.graphql` files for static queries, inline definitions for variable interpolation
- Loader pattern (`_loader.sh`) with `require <module>` for dependency management
- Query functions: `query_get()`, `query_load_graphql_file()`, `query_exists()`, `query_list_for_app()`
- Explicit parameters replace global variables for testability (e.g., `login_user_id`, `login_session_id` passed as function args)
- **Configuration system** (three-tier value resolution):
  - `settings.sh`: File I/O layer - read/write `gqlRequest.conf` with comment preservation
  - `config.sh`: Configuration layer - implements priority: env vars > config file > hardcoded defaults
    - Provides getters for config values, paths (cache/tunnel/log dirs), and app configuration
    - Functions return values vs globals for explicit dependencies
  - `config_cli.sh`: CLI interface - `dr gqlRequest config` commands (get/set/list)
  - Config keys: `RISK_USER_EMAIL`, `CLIENT_USER_KEY_ID`, `DEFAULT_APP`, `DEFAULT_ENVIRONMENT`, `GCP_PROJECT_*`, `GCP_REGION`, `GCP_CLUSTER_SUFFIX`
  - Main script loads config at startup via `settings_ensure_config_exists` and respects user defaults
- **Query management CLI** (user-defined query lifecycle):
  - `query_cli.sh`: Query CLI interface - `dr gqlRequest query-add/query-list/query-which` commands
  - `query-add <file.graphql>`: Copy external .graphql files to queries/ directory with validation and overwrite confirmation
  - `query-list`: Display all available queries (built-in vs user-added) with line counts
  - `query-which <name>`: Show query file path and content with line numbers
  - Built-in query detection: Maintains list of shipped queries (echo, test, userInfo, etc.) for classification
  - Interactive confirmations for destructive operations (overwrite existing queries)
- **Kubectl context management** (caching to avoid redundant switches):
  - `context.sh`: Context cache layer - checks if switch needed based on cached app/env/context
  - `kube-context.sh`: Low-level kubectl operations - fully internalized context switching, project/cluster name mapping, gcloud authentication
  - Cache file: `~/.cache/gqlrequest/context-cache.json` (per-app context tracking)
- **AI skill management** (Claude Code integration):
  - `dr gqlRequest skill` / `skill link`: Creates symlink from `ai-skill-gql-request/` to `~/.claude/skills/dr-gql-request/`
  - `dr gqlRequest skill unlink`: Removes symlink with validation (refuses non-symlink removal)
  - `dr gqlRequest skill status`: Shows symlink status with source/target validation
  - Interactive overwrite confirmation when recreating existing symlinks

#### Example: System Setup Scripts with Bundled Resources (`scripts/system/`)

System setup scripts can bundle required resources in sibling directories for offline installation:

**nerdFonts.sh pattern:**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="${SCRIPT_DIR}/.nerdFonts"
```

**Structure:**

```
scripts/system/
├── fonts/
│   ├── nerdFonts.sh         # Setup script (registers fonts with fontconfig)
│   └── .nerdFonts/          # Bundled Nerd Fonts
│       ├── install.sh       # Font management script
│       ├── _core/           # Font utilities
│       └── [font-dirs]/     # Font families
└── tmux/
    └── tmux-setup.sh        # Embeds config directly (no bundle)
```

**Key characteristics:**

- Uses `BASH_SOURCE` for dynamic path resolution (works regardless of execution location)
- Registers fonts with fontconfig (`fc-cache -f "$BUNDLE_DIR"`) - no copying or symlinking
- Fonts live permanently in bundle directory, registered in-place with system font cache
- Removes external dependencies for offline use
- Follows same UX as other setup scripts: loadHelpers integration, informative output
- Pattern: `SCRIPT_DIR` from `BASH_SOURCE`, then reference `.{resource}/` subdirectories

### Installed Location (`~/.local/share/dotrun/`)

Contains symlinks (dev) or copies (production) of `core/shared/dotrun/` contents.

## Core Concepts

### Shell Integration

DotRun bootstraps through a two-file pattern that integrates with shell initialization:

**User's shell config (`.bashrc`/`.zshrc`/`.config/fish/config.fish`):**

```bash
# Source DotRun configuration
[[ -f "$HOME/.drrc" ]] && source "$HOME/.drrc"
```

**`~/.drrc` (user-facing config file):**

- Sets environment variables (`DR_CONFIG`, `DR_LOAD_HELPERS`)
- Sources `loadHelpers.sh` for helper function access
- Sources `.dr_config_loader` for shell integration

**`~/.local/share/dotrun/.dr_config_loader` (shell integration engine):**

- Detects current shell (`bash`/`zsh`/`fish`)
- Adds `~/.local/bin` to PATH
- Sources shell-specific configs from `~/.local/share/dotrun/shell/<shell>/`
- Loads completion system with plugin manager compatibility (Zsh uses fpath + precmd hook)

**Workflow:**

1. Shell starts → sources `.bashrc`/`.zshrc`
2. `.bashrc`/`.zshrc` → sources `~/.drrc`
3. `~/.drrc` → sources `.dr_config_loader`
4. `.dr_config_loader` → sources `configs.sh`, `aliases.sh`, and completion files

**Key features:**

- **Plugin manager compatibility**: Zsh completion uses fpath discovery + self-cleaning precmd hook for turbo-mode loaders (oh-my-zsh, zinit, sheldon)
- **Shell detection**: Automatic shell type detection via `$BASH_VERSION`/`$ZSH_VERSION`/`$FISH_VERSION`
- **Conditional completion**: Bash detects ble.sh and loads enhanced completion with colors
- **Lazy loading**: Configs → Aliases → Completion (ordered for dependency resolution)
- **Unified filesystem finder**: All four completion engines (bash, zsh, fish, ble.sh) implement the same `_dr_filesystem_find` pattern with identical argument signatures `(context, type, depth, subcontext, pattern)`, ensuring consistent behavior across shells
- **v3.1.3 Fish fixes**: `string match` crash (reordered `--` separator before pattern) and `$` regex escaping in `aliases.sh`/`configs.sh` to prevent variable interpolation

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
- **Dynamic path resolution**: Use `BASH_SOURCE` for script-relative paths (works regardless of execution location)
  - Pattern: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
  - Used for: referencing sibling resources, bundled directories, AI skill symlink management
  - Example use cases: `ai_skill.sh`, `fonts-setup.sh` (bundle access), `run.sh` (skill scripts)
- **Hidden folder filtering**: Use `-name '.*' -prune -o` pattern in all `find` commands to prevent traversing hidden directories
  - Pattern: `find "$dir" -name '.*' -prune -o -type f -name "*.sh" -print`
  - Applies to: script search (`scripts.sh`), tree display (`list_feature_files_tree.sh`), shell completions (bash, zsh, fish, ble.sh)
  - Prevents `find` from descending into hidden directories like `.gqlRequest/`, `.nerdFonts/`
  - Belt-and-suspenders approach: `-prune` prevents traversal, post-filtering with pattern matching provides additional safety
  - **v3.1.3**: Applied consistently across all completion engines — zsh now uses prune-before-traversal instead of post-filtering

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

**Version 3.1.2 Updates:**

- **SKILL.md rewritten** with structured frontmatter: `mandatory-triggers`, `trigger-keywords`, and `decision-rule` fields replace verbose prose description
- **Decision Routing Matrix** added — table mapping user intent to `dr` commands for fast agent routing
- **Discovery Before Creation** workflow enforced — mandatory `dr -L` check before creating scripts
- **AGENTS.md** restructured with action-oriented routing, explicit `NEVER` rules, and migration workflow
- **Reference files** condensed — architecture, commands, and migration docs trimmed for efficiency

## Recent Changes (v3.1.3)

### Hidden Folder Filtering — Consistent Prune Pattern

- **`-name '.*' -prune -o` pattern** applied consistently across all `find` commands to prevent traversing hidden resource directories (`.gqlRequest/`, `.nerdFonts/`)
  - `scripts.sh`: `find_script_file()` fallback search now prunes hidden directories
  - `list_feature_files_tree.sh`: Both broken symlink detection and main file discovery now prune hidden directories
  - All shell completion engines: unified filesystem finder functions use prune-before-traversal
  - `dr_completion.zsh`: Replaced `! -name '.*' -print0` (post-filter) with `-name '.*' -prune -o ... -print0` — prevents `find` from descending into hidden directories rather than filtering results afterward

### Fish Shell Fixes

- **`string match` crash**: Fixed `string match: -*: unknown option` error when completing patterns starting with a dash
  - Root cause: `string match -q "-*" -- "$token"` — Fish interprets `-*` as a flag even with `--` after it
  - Fix: Reorder to `string match -q -- "-*" "$token"` (put `--` before the pattern)
- **`$` regex escaping**: Fixed `shell/fish/aliases.sh` and `shell/fish/configs.sh` where unescaped `$` in `string match` regex patterns was interpreted as Fish variable reference, causing silent match failures

### Shell Completion — Unified Filesystem Finder Rewrite

All four completion engines (Bash, ble.sh, Fish, Zsh) now share an identical `_dr_filesystem_find` abstraction with the same argument signature `(context, type, depth, [subcontext], [pattern])`:

- **Bash** (`dr_completion.bash`): Complete rewrite — unified `_dr_filesystem_find` replaces 6 separate per-feature helpers (`_dr_get_folders`, `_dr_get_scripts`, `_dr_get_alias_folders`, etc.). Helper functions (`_dr_emit_feature_context`, `_dr_emit_recursive_search`, `_dr_emit_folders_only`, `_dr_complete_feature`, `_dr_complete_list_filter`) mirror the zsh reference logic
- **ble.sh** (`dr_completion_ble.sh`): Near-complete rewrite — `_dr_ble_filesystem_find` now supports all three features (scripts, aliases, configs) with per-feature icons and colors. Previously only supported scripts. Full color scheme matching zsh (green=scripts, purple=aliases, red=configs, blue=collections, yellow=folders, gray=hints). Fixed script icon from ⚙ to 🚀
- **Fish** (`dr_completion.fish`): Complete rewrite — `__dr_filesystem_find` replaces ad-hoc `find` calls. Three unified generators (`__dr_complete_feature`, `__dr_complete_recursive`, `__dr_complete_folders_only`) with tab-separated `value\tdescription` output for per-item emoji descriptions
- **Zsh** (`dr_completion.zsh`): Minor update — pruning pattern updated to prevent traversal rather than post-filtering

### Fish Completion — Sorting & Descriptions

- **Folders-first ordering**: All completions now show folders (A-Z) before files (A-Z) using Fish's `-k` (keep order) flag to preserve generator output order
- **Per-item emoji descriptions** via tab-separated output from generator functions:
  - Folders: `📁 Folder`
  - Scripts: `🚀 Script`
  - Aliases: `📝 Alias file`
  - Configs: `⚙️  Config`
  - Collection subcommands: `➕`, `📋`, `🔄`, `⬆️`, `🗑️`
- **Namespace flags removed from root TAB**: Empty `dr <TAB>` now shows only folders and scripts (no `-s`, `-a`, `-c`, `-col` flags), matching zsh behavior

### Bash & ble.sh Completion Parity

- **Root completion**: Empty TAB shows only folders + scripts (no commands/namespace flags), matching zsh
- **Namespace contexts**: `-s`/`-a`/`-c` namespaces show folders + files (not subcommands), matching zsh
- **Missing collection commands**: Added `set`, `sync`, `update` to collections subcommand completion (previously only had `list`, `list:details`, `remove`)
- **Recursive search**: All shells now support recursive pattern matching across all features (scripts, aliases, configs)

### dev.sh Development Setup

- **Missing `help-messages/` symlink**: The deep `core/help-messages/` directory tree was only present as old copies at target, not as symlinks — edits during development wouldn't take effect. Now symlinks the entire directory.
- **Stale symlink cleanup**: Added cleanup step before shell file symlinking — removes dangling symlinks from deleted source files (e.g., removed `enable-colors.sh`)

## Previous Changes (v3.1.2)

### Zsh Autocomplete — Universal Plugin Manager Compatibility

- **fpath-based completion discovery** replaces direct `compdef` call — works with oh-my-zsh, zinit, sheldon, prezto, or manual `compinit`
- **New `shell/zsh/completions/_dr`** symlink added for standard zsh completion convention (`#compdef dr` header auto-discovered by `compinit`)
- **Self-cleaning `precmd` hook** (`_dr_ensure_completion`) ensures `compdef` registration survives turbo-mode plugin managers that reinitialize `compinit` asynchronously
- **`dev.sh` updated** to symlink the new `completions/` subdirectory during development setup
- Eliminates need for user-specific plugin manager configuration

### loadHelpers.sh Default Variables

- **`_DR_LOAD_DEPTH`** now uses `${_DR_LOAD_DEPTH:-0}` to preserve value across re-sourcing instead of unconditionally resetting to 0
- **`_DR_LOAD_DEPTH_MAX`** now uses `${_DR_LOAD_DEPTH_MAX:-10}` allowing user override of circular dependency protection limit
- **Help message extracted** to external file (`core/help-messages/helpers/loadHelpers-usage.sh`) with ANSI color formatting, consistent with project-wide help message separation pattern

### Shell Completion — Unified Filesystem Finder Across All Shells

All four completion engines now share an identical `_dr_filesystem_find` abstraction:

- **Zsh** (`dr_completion.zsh`): `_dr_global_filesystem_find` — reference implementation with `_dr_get_feature_context` / `_dr_display_feature_context` get+display pipeline, lazy-loaded categories, and zstyle-based coloring via `_wanted` tags
- **Bash** (`dr_completion.bash`): `_dr_filesystem_find` — replaces per-feature helpers (`_dr_get_folders`, `_dr_get_scripts`, `_dr_get_alias_folders`, etc.) with a single unified function. Helper functions (`_dr_emit_feature_context`, `_dr_emit_recursive_search`, `_dr_emit_folders_only`, `_dr_complete_feature`, `_dr_complete_list_filter`) mirror the zsh completion logic structure
- **ble.sh** (`dr_completion_ble.sh`): `_dr_ble_filesystem_find` — now supports all three features (scripts, aliases, configs) with per-feature icons and colors. Previously only supported scripts. Helper functions (`_dr_ble_emit_feature_context`, `_dr_ble_emit_recursive_search`, `_dr_ble_emit_folders_only`, `_dr_ble_complete_feature`, `_dr_ble_complete_list_filter`) use `ble/complete/cand/yield` with ANSI color display strings
- **Fish** (`dr_completion.fish`): `__dr_filesystem_find` — replaces ad-hoc `find` calls with a unified function. Completion generators (`__dr_complete_feature_context`, `__dr_complete_recursive_search`, `__dr_complete_list_filter`) and condition predicates (`__dr_needs_first_arg`, `__dr_in_*_namespace`, etc.) provide declarative completion registration

**Shared argument signature**: `(context, type, depth, [subcontext], [pattern])`

- `context`: `scripts` | `aliases` | `configs` — maps to the correct base directory and file extension
- `type`: `file` | `directory` — determines find `-type` filter
- `depth`: `single` | `all` — controls `-maxdepth 1` vs recursive search
- `subcontext`: optional relative path for hierarchical folder navigation
- `pattern`: optional case-insensitive substring match via `-ipath`

### Unified Filesystem Finder Architecture (v3.1.2)

Initial implementation of unified `_dr_filesystem_find` abstraction across all completion engines:

- **Zsh** (`dr_completion.zsh`): `_dr_global_filesystem_find` — reference implementation with `_dr_get_feature_context` / `_dr_display_feature_context` get+display pipeline, lazy-loaded categories, and zstyle-based coloring via `_wanted` tags
- **Bash** (`dr_completion.bash`): `_dr_filesystem_find` — unified function replaces per-feature helpers. Helper functions (`_dr_emit_feature_context`, `_dr_emit_recursive_search`, `_dr_emit_folders_only`, `_dr_complete_feature`, `_dr_complete_list_filter`) mirror zsh logic
- **ble.sh** (`dr_completion_ble.sh`): `_dr_ble_filesystem_find` — supports all three features (scripts, aliases, configs) with per-feature icons and colors. Helper functions use `ble/complete/cand/yield` with ANSI color display strings
- **Fish** (`dr_completion.fish`): `__dr_filesystem_find` — unified function with completion generators (`__dr_complete_feature`, `__dr_complete_recursive`, `__dr_complete_folders_only`) and declarative registration

**Shared argument signature**: `(context, type, depth, [subcontext], [pattern])`

- `context`: `scripts` | `aliases` | `configs` — maps to base directory and file extension
- `type`: `file` | `directory` — determines find `-type` filter
- `depth`: `single` | `all` — controls `-maxdepth 1` vs recursive search
- `subcontext`: optional relative path for hierarchical folder navigation
- `pattern`: optional case-insensitive substring match via `-ipath`
