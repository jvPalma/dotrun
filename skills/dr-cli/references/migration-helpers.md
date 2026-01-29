# DotRun Helper System Reference

Authoritative reference for DotRun's helper system, covering available helpers, `loadHelpers` usage patterns, and practical examples.

---

## Table of Contents

1. [Overview](#overview)
2. [Helper Locations](#helper-locations)
3. [Available Helpers](#available-helpers)
4. [loadHelpers Function](#loadhelpers-function)
5. [Usage Patterns](#usage-patterns)
6. [Migration Examples](#migration-examples)
7. [Environment Variables](#environment-variables)

---

## Overview

DotRun's helper system provides reusable functions organized by domain. Helpers are loaded on-demand using the `loadHelpers` function with flexible pattern matching.

**Key Features:**

- Pattern-based loading (exact path, collection, filename)
- Circular dependency protection
- Bash 3+ compatibility
- Duplicate loading prevention
- Collection-based organization

---

## Helper Locations

Helpers are stored in `~/.config/dotrun/helpers/` with domain-based organization:

```bash
~/.config/dotrun/helpers/
├── global/              # Core utilities (colors, logging, pkg management)
├── git/                 # Git operations (branches, PRs, diffs)
├── validation/          # Linting and validation
├── ai/claude/           # Claude AI integration
├── system/              # System-level operations
├── utils/               # General utilities
└── 01-dotrun-anc/       # Namespaced collections (custom/org-specific)
```

**Core System Files:**

- `~/.local/share/dotrun/helpers/loadHelpers.sh` - Main loader function
- `/home/user/dotrun/core/config/dotrun/helpers/` - Core defaults

---

## Available Helpers

### Global Helpers (`global/`)

| Path                        | Purpose                  | Key Functions                                                                                                | Dependencies |
| --------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------ | ------------ |
| `global/colors.sh`          | Terminal color constants | `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `GRAY`, `BOLD`, `RESET`                                            | `tput`       |
| `global/logging.sh`         | Structured logging       | `log_info()`, `log_error()`, `log_warning()`, `log_success()`, `log_debug()`                                 | `colors.sh`  |
| `global/pkg.sh`             | Package management       | `detect_lang()`, `pkg_install_hint()`, `validatePkg()`, `detect_shell()`                                     | -            |
| `global/filesystem.sh`      | File operations          | `get_files_content_inside_history_dir()`, `add_history_files_inside_history_dir()`, `cleanup_temp_files()`   | -            |
| `global/system_prompt.sh`   | Interactive prompts      | `prompt_editor_review()`                                                                                     | `colors.sh`  |
| `global/install_helpers.sh` | Installation utilities   | `check_already_installed()`, `install_package()`, `install_github_release()`, `detect_arch()`, `detect_os()` | `logging.sh` |

### Git Helpers (`git/`)

| Path                              | Purpose                    | Key Functions                                                                                               | Dependencies          |
| --------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------- |
| `git/git.sh`                      | Core Git operations        | `git_repo_root()`, `git_current_branch()`, `git_default_branch()`, `get_branch_info()`, `cleanup_on_exit()` | `colors.sh`, `pkg.sh` |
| `git/git_pr.sh`                   | PR management              | `prNewDraft()`, `prDraftToOpen()`, `prReadyAddLabelsAndReviewers()`                                         | `git.sh`              |
| `git/bash-interactive-cleanup.sh` | Interactive branch cleanup | Branch selection UI, deletion workflows                                                                     | `git.sh`              |
| `git/git_code_diffs.sh`           | Diff generation            | Code diff utilities                                                                                         | `git.sh`              |

### Validation Helpers (`validation/`)

| Path                 | Purpose           | Key Functions      | Dependencies |
| -------------------- | ----------------- | ------------------ | ------------ |
| `validation/lint.sh` | Linting utilities | `run_shell_lint()` | `pkg.sh`     |

### AI Helpers (`ai/claude/`)

| Path                                      | Purpose                | Key Functions             | Dependencies |
| ----------------------------------------- | ---------------------- | ------------------------- | ------------ |
| `ai/claude/generate.sh`                   | Claude CLI integration | `generate()`              | -            |
| `ai/claude/prepare_code_review_prompt.sh` | Code review prompts    | Prompt assembly functions | -            |

---

## loadHelpers Function

### Syntax

```bash
loadHelpers <pattern> [--list]
```

### Pattern Resolution Order

From most to least specific:

1. **Absolute path**: `/full/path/to/helper.sh`
2. **Exact path with extension**: `global/colors.sh`
3. **Path without extension**: `global/colors`
4. **Collection/path**: `dotrun-anc/gcp/workstation`
5. **Filename only**: `colors` (searches all directories)

### Special Patterns

- `@collection-name` - Load all helpers from a collection

  ```bash
  loadHelpers @dotrun-anc  # Loads all from 01-dotrun-anc/
  ```

- `--list` flag - Preview matches without loading
  ```bash
  loadHelpers git/git --list
  ```

### Architecture

**Deduplication:**

- Uses canonical paths (`_dr_realpath`) to prevent duplicate loading
- Tracks loaded helpers in `_DR_LOADED_HELPERS` (associative array in Bash 4+, indexed in Bash 3)

**Safety:**

- Circular dependency protection (max depth: 10)
- Security check: ensures helpers are within `~/.config/dotrun/helpers/`
- Graceful error handling with detailed messages

---

## Usage Patterns

### Basic Pattern (Recommended)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers
loadHelpers global/colors
loadHelpers global/logging

main() {
  log_info "Script started"
  echo -e "${GREEN}Success!${NC}"
}

main "$@"
```

### Multiple Helpers

```bash
# Sequential loading (dependencies)
loadHelpers global/colors
loadHelpers global/logging  # depends on colors

# Or load related helpers
loadHelpers git/git
loadHelpers git/git_pr
```

### Collection Loading

```bash
# Load all helpers from a custom collection
loadHelpers @dotrun-anc

# Or load specific helper from collection
loadHelpers dotrun-anc/gcp/workstation
```

### Verbose Debugging

```bash
# Enable verbose output for troubleshooting
DR_HELPERS_VERBOSE=1 loadHelpers git/git
```

### Conditional Loading

```bash
# Load helper only if environment variable is set
[[ -n "${USE_AI:-}" ]] && loadHelpers ai/claude/generate
```

---

## Migration Examples

### Before: Hardcoded Paths

```bash
#!/usr/bin/env bash
source "$DR_CONFIG/helpers/global/colors.sh"
source "$DR_CONFIG/helpers/global/logging.sh"
source "$DR_CONFIG/helpers/git/git.sh"

echo -e "${BLUE}Starting...${NC}"
log_info "Checking git status"
git_current_branch
```

### After: loadHelpers

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/colors
loadHelpers global/logging
loadHelpers git/git

echo -e "${BLUE}Starting...${NC}"
log_info "Checking git status"
git_current_branch
```

**Benefits:**

- ✅ No hardcoded `$DR_CONFIG` references
- ✅ Automatic deduplication
- ✅ Bash 3+ compatibility
- ✅ Flexible pattern matching
- ✅ Security validation

---

### Before: Direct Function Calls

```bash
#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_error "Something failed"
log_info "Process complete"
```

### After: Helper-Based

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/logging

log_error "Something failed"
log_info "Process complete"
```

**Benefits:**

- ✅ Consistent formatting across all scripts
- ✅ Centralized maintenance
- ✅ `DEBUG` mode support via `log_debug()`
- ✅ Pipe support: `echo "message" | log_info`

---

### Before: Git Operations

```bash
#!/usr/bin/env bash

current_branch=$(git symbolic-ref --quiet --short HEAD)
default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's|origin/||')
repo_root=$(git rev-parse --show-toplevel)

if [[ -z "$default_branch" ]]; then
  default_branch="master"
fi

echo "Current: $current_branch"
echo "Default: $default_branch"
echo "Root: $repo_root"
```

### After: Git Helpers

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers git/git

current_branch=$(git_current_branch)
default_branch=$(git_default_branch)
repo_root=$(git_repo_root)

echo "Current: $current_branch"
echo "Default: $default_branch"
echo "Root: $repo_root"
```

**Benefits:**

- ✅ Honors `GIT_DEFAULT_BRANCH` env var
- ✅ Handles detached HEAD states
- ✅ Consistent behavior across scripts
- ✅ Error handling built-in

---

### Before: Package Detection

```bash
#!/usr/bin/env bash

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed"
  if command -v apt &>/dev/null; then
    echo "Install with: sudo apt install jq"
  elif command -v brew &>/dev/null; then
    echo "Install with: brew install jq"
  fi
  exit 1
fi
```

### After: pkg.sh Helper

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/pkg

validatePkg git
validatePkg jq
```

**Benefits:**

- ✅ Automatic package manager detection (apt, dnf, pacman, brew, pkg)
- ✅ Helpful install hints
- ✅ Consistent error messages

---

### Before: Shell Detection

```bash
#!/usr/bin/env bash

if [[ -n "${ZSH_VERSION:-}" ]]; then
  shell="zsh"
elif [[ -n "${BASH_VERSION:-}" ]]; then
  shell="bash"
elif [[ -n "${FISH_VERSION:-}" ]]; then
  shell="fish"
else
  shell="unknown"
fi

echo "Detected shell: $shell"
```

### After: detect_shell()

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/pkg

shell=$(detect_shell)
echo "Detected shell: $shell"
```

**Benefits:**

- ✅ Checks process tree (not just `$BASH_VERSION`)
- ✅ Handles edge cases (e.g., bash scripts running in zsh)
- ✅ Reliable fallbacks

---

## Environment Variables

### loadHelpers Configuration

| Variable             | Default            | Purpose                                       |
| -------------------- | ------------------ | --------------------------------------------- |
| `DR_CONFIG`          | `~/.config/dotrun` | Helpers search path                           |
| `DR_HELPERS_VERBOSE` | `0`                | Enable verbose loading output (`1` = verbose) |
| `DR_HELPERS_QUIET`   | `0`                | Suppress non-error output (`1` = quiet)       |
| `DR_LOAD_HELPERS`    | (auto)             | Path to `loadHelpers.sh` (set by install.sh)  |

### Helper-Specific Variables

| Variable             | Default           | Purpose                           | Used By            |
| -------------------- | ----------------- | --------------------------------- | ------------------ |
| `DEBUG`              | `false`           | Enable debug logging              | `logging.sh`       |
| `GIT_DEFAULT_BRANCH` | (auto)            | Override default branch detection | `git.sh`           |
| `HISTORY_DIR`        | (script-specific) | Command history storage           | `filesystem.sh`    |
| `HISTORY_SIZE`       | (script-specific) | Max history entries               | `filesystem.sh`    |
| `EDITOR`             | `nano`            | Default editor for prompts        | `system_prompt.sh` |

### Color Variables (from `colors.sh`)

Available after `loadHelpers global/colors`:

```bash
RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY ORANGE
RESET NC  # Both reset colors
BOLD
```

Usage:

```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}${BOLD}Critical Error${NC}"
```

### Logging Variables

Available after `loadHelpers global/logging`:

```bash
log_info "message"     # Blue [INFO]
log_error "message"    # Red [ERROR] (stderr)
log_warning "message"  # Yellow [WARNING]
log_success "message"  # Green [SUCCESS]
log_debug "message"    # Magenta [DEBUG] (only if DEBUG=true)
```

Pipe support:

```bash
git status | log_info
cat error.log | log_error
```

---

## Advanced Patterns

### Fallback Loading

```bash
# Try specific helper, fallback to generic
loadHelpers dotrun-anc/custom || loadHelpers global/default
```

### Preview Before Loading

```bash
# Check what will be loaded
loadHelpers git/git --list

# Then load
loadHelpers git/git
```

### Namespace Isolation

```bash
# Load from specific collection only
loadHelpers 01-dotrun-anc/gcp/workstation.sh  # Exact with namespace
```

---

## Common Gotchas

1. **Missing `DR_LOAD_HELPERS` Check**

   ```bash
   # ❌ Wrong - will fail if DR_LOAD_HELPERS not set
   source "$DR_LOAD_HELPERS"

   # ✅ Correct - conditional load
   [[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
   ```

2. **Circular Dependencies**
   - Max depth: 10 levels
   - Error: "Maximum helper loading depth exceeded"
   - Fix: Review helper dependencies

3. **Ambiguous Patterns**
   - Multiple matches trigger warning
   - Use more specific patterns or `--list` to preview

4. **Security Boundary**
   - Helpers must be in `~/.config/dotrun/helpers/`
   - Absolute paths outside this directory are rejected

---

## Best Practices

1. **Always use `set -euo pipefail`** for script safety
2. **Load helpers at script top** (after shebang and set)
3. **Use specific patterns** when possible (avoid filename-only)
4. **Document dependencies** in script header
5. **Test with `--list`** when creating new helpers
6. **Organize by domain** (git/, validation/, ai/, etc.)
7. **Keep helpers focused** - single responsibility principle

---

## Template Usage

Start new scripts from template:

```bash
dr new my-script
```

Generated template includes:

- ✅ Proper `loadHelpers` setup
- ✅ `set -euo pipefail`
- ✅ `colors` helper pre-loaded
- ✅ DOC comments for skill migration

---

## Troubleshooting

### Helper Not Found

```bash
# Enable verbose mode
DR_HELPERS_VERBOSE=1 loadHelpers my-helper

# Check available helpers
find ~/.config/dotrun/helpers -name "*.sh"

# Preview matches
loadHelpers my-helper --list
```

### Duplicate Loading Warning

```bash
# This is normal - loadHelpers prevents re-sourcing
loadHelpers global/colors  # First load
loadHelpers global/colors  # Skipped (already loaded)
```

### Wrong Helper Version

```bash
# Check which helper is loaded
type -a log_info

# Force reload (restart shell or use new subshell)
bash -c 'source "$DR_LOAD_HELPERS" && loadHelpers global/logging && log_info "test"'
```

---

## Summary

The DotRun helper system provides:

- **46 helper files** organized by domain
- **Flexible loading** with pattern matching
- **Automatic deduplication** via canonical paths
- **Security validation** within allowed directories
- **Bash 3+ compatibility** for broad platform support
- **Circular dependency protection** for stability

Use `loadHelpers` in all new scripts and migrate existing scripts incrementally during refactors.
