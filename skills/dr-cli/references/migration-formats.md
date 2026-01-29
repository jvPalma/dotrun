# DotRun File Format Reference

This document describes the file formats and naming conventions used by DotRun for aliases, configs, and scripts.

## Directory Structure

```
~/.config/dotrun/
├── aliases/          # Shell aliases (*.aliases)
├── configs/          # Environment variables and shell configs (*.config)
├── scripts/          # Executable scripts organized by category
└── bin/              # Additional executables (optional)
```

---

## 1. Alias Files

**Location:** `~/.config/dotrun/aliases/`

**Naming Convention:** `NN-category.aliases`

- `NN`: Two-digit number (00-99) for load order
- `category`: Descriptive name (navigation, git, docker, etc.)
- Extension: `.aliases` (required)

### Format Structure

```bash
#!/usr/bin/env bash

# DotRun Aliases - {category} Category
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'dr -s set {category}' to add aliases to this category.

# Optional: Shell-specific aliases
[[ $CURRENT_SHELL == "bash" ]] && {
  alias ppp="clear; source ~/.bashrc; echo 'sourced ~/.bashrc'"
}

[[ $CURRENT_SHELL == "zsh" ]] && {
  alias ppp="clear; source ~/.zshrc; echo 'sourced ~/.zshrc'"
}

# Standard aliases
alias anchor="cd $ANCHOR_SRC_PATH"
alias fe="clear; cd $ANCHOR_SRC_PATH/source/js/anchorage/"

# Aliases calling DotRun scripts
alias co="dr git/branch/co"
alias prFix="dr git/prs/prFix"

# Multi-line help text aliases
gitHelpCommands=""
gitHelpCommands+="\n  gst        git status"
gitHelpCommands+="\n  gadd       git add"
alias ghelp="echo -e '$gitHelpCommands \n'"

# shellcheck directives (if needed)
# shellcheck disable=SC2139
```

### Key Features

- Shebang: `#!/usr/bin/env bash`
- Standard comment header with category name
- Shell-specific blocks using `$CURRENT_SHELL`
- DotRun script aliases: `alias name="dr category/script"`
- Multi-line help text using concatenation
- Optional shellcheck directives

### Examples

**Simple navigation aliases:**

```bash
alias ...='cd ../..'
alias ....='cd ../../..'
```

**DotRun script aliases:**

```bash
alias gfe="dr git/commits/fetch"
alias co="dr git/branch/co"
```

**Conditional aliases:**

```bash
[[ $CURRENT_SHELL == "bash" ]] && {
  alias ppp="clear; source ~/.bashrc; echo 'sourced ~/.bashrc'"
}
```

---

## 2. Config Files

**Location:** `~/.config/dotrun/configs/`

**Naming Convention:** `NN.category.config` or `NN-category.config`

- `NN`: Two-digit number (00-99) for load order
- `category`: Descriptive name (main, tools, system, etc.)
- Extension: `.config` (required)

### Format Structure

```bash
#!/usr/bin/env bash

# DotRun Configuration - {category}
# Environment variables and shell configurations

# Standard export variables
export GIT_USERNAME='jvPalma'
export GIT_DEFAULT_BRANCH='master'
export EDITOR="nano"

# Conditional configurations
if command -v brew >/dev/null 2>&1; then
  eval "$($(brew --prefix)/bin/brew shellenv)"
fi

# NVM/Node setup
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Complex conditional logic
if command -v nvm >/dev/null 2>&1; then
  VERSION_IS_INSTALLED=$(nvm ls "$NVM_VERSION_TO_USE")
  CURRENT_VERSION=$(nvm current)

  if [[ $VERSION_IS_INSTALLED == *"N/A"* ]]; then
    nvm install "$NVM_VERSION_TO_USE" >/dev/null
  fi
fi
```

### Key Features

- Shebang: `#!/usr/bin/env bash`
- Export statements for environment variables
- Conditional blocks for tool-specific configs
- Command availability checks: `command -v tool >/dev/null 2>&1`
- Source statements for external configs

### Secure Config Files

**Location:** `~/.config/dotrun/configs/00.secure/`

**Format:** Same as regular configs but for sensitive data

```bash
#!/usr/bin/env bash

# DotRun Secure Configuration
# This file contains sensitive values and has restricted permissions.
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

export GEMINI_API_KEY="AIzaSy..."
export OPENAI_API_KEY="sk-proj-..."
export TELEGRAM_BOT_TOKEN="7875312552:AAGc..."
```

**Important:** These files should have restricted permissions (600)

---

## 3. Script Files

**Location:** `~/.config/dotrun/scripts/{category}/`

**Naming Convention:** `scriptName.sh`

- Scripts are organized in category subdirectories
- Categories can be nested: `git/branch/co.sh`, `git/commits/fetch.sh`
- Extension: `.sh` (required)

### Format Structure (Template)

```bash
#!/usr/bin/env bash
### DOC
# One line description about what this script does
### DOC
#
# Long multiline description of this script
#
# Usage/Example:
#   dr {category}/{scriptName} [args]
#   dr {category}/{scriptName} -f <file>
#
# Options:
#   -f, --file <file>    Description of option
#   -h, --help           Show help message
#
# Required Tools:
#   git, jq, curl
#
### DOC

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers
loadHelpers global/colors
loadHelpers global/logging
loadHelpers git/git

# Configuration constants
CONSTANT_NAME="value"

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

helperFunction() {
  local param="$1"
  echo "Processing: $param"
}

showHelp() {
  cat <<'EOF'
Usage: dr {category}/{scriptName} [OPTIONS] <args>

Description of what the script does.

Options:
  -f, --file <file>    Description
  -h, --help           Show this help

Examples:
  dr {category}/{scriptName} value
  dr {category}/{scriptName} -f file.txt
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Function
# ─────────────────────────────────────────────────────────────────────────────

main() {
  # Argument parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        showHelp
        exit 0
        ;;
      -f|--file)
        file="$2"
        shift 2
        ;;
      -*)
        echo "ERROR: Unknown option: $1" >&2
        showHelp
        exit 1
        ;;
      *)
        arg="$1"
        shift
        ;;
    esac
  done

  # Script logic
  echo "Running script..."
}

main "$@"
```

### Key Components

#### 1. Triple DOC Blocks

```bash
### DOC
# Short description
### DOC
#
# Long description with usage examples
#
### DOC
```

- First block: One-line summary
- Second block: Detailed description, usage, options, examples
- Used by DotRun's documentation system

#### 2. Script Initialization

```bash
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers
loadHelpers global/colors
loadHelpers git/git
```

- `set -euo pipefail`: Exit on error, undefined variables, pipe failures
- `DR_LOAD_HELPERS`: Enables dual-mode execution (standalone or via DotRun)
- `loadHelpers`: Load helper functions from `~/.config/dotrun/helpers/`

#### 3. Argument Parsing Pattern

```bash
main() {
  local option=""
  local arg=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        showHelp
        exit 0
        ;;
      -o|--option)
        option="$2"
        shift 2
        ;;
      -*)
        echo "ERROR: Unknown option: $1" >&2
        exit 1
        ;;
      *)
        arg="$1"
        shift
        ;;
    esac
  done

  # Script logic here
}

main "$@"
```

#### 4. Help Function

```bash
showHelp() {
  cat <<'EOF'
Usage: dr category/script [OPTIONS] <args>

Description

Options:
  -f, --file    Description
  -h, --help    Show help

Examples:
  dr category/script example
EOF
}
```

### Script Complexity Levels

**Simple Script (minimal structure):**

```bash
#!/usr/bin/env bash
### DOC
# Display current git branch name
### DOC
#
# Usage: dr git/branch/branchName
#
### DOC

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
loadHelpers git/git

main() {
  echo -e "\t ${CYAN} co ${YELLOW} $(git_current_branch)"
}

main "$@"
```

**Complex Script (full structure):**

```bash
#!/usr/bin/env bash
### DOC
# Smart git checkout with branch name normalization
### DOC
#
# [Detailed description]
# Usage/Examples/Options as shown in template
#
### DOC

set -euo pipefail

# Constants
NAME_TO_REPLACE="oldname"
NEW_NAME="newname"

# Helper functions
usage() { ... }
ensure_git_repo() { ... }
sanitize_branch_name() { ... }

# Main logic
main() {
  [[ $# -eq 1 ]] || usage
  ensure_git_repo

  # Complex logic here
}

main "$@"
```

---

## 4. Naming Conventions

### Load Order

Files are loaded in alphanumeric order. Use numeric prefixes to control precedence:

```
00-shell-specific.aliases    # Load first (shell setup)
01-navigation.aliases        # Early (basic navigation)
10-code-navigation.aliases   # Mid (project-specific)
15-git.aliases               # Mid (git commands)
25-main.aliases              # Later (main commands)
40-custom.aliases            # Late (user customizations)
```

### Category Naming

- **Lowercase with hyphens:** `code-navigation`, `git-commands`
- **Descriptive:** Clearly indicates content
- **Hierarchical scripts:** `git/branch/co.sh`, `git/commits/fetch.sh`

### Variable Naming

- **Uppercase for exports:** `GIT_USERNAME`, `EDITOR`
- **Uppercase for constants:** `MIN_SIZE_BYTES`, `OUTPUT_DIR`
- **Lowercase for locals:** `local file=""`, `local result`

---

## 5. Special Patterns

### DotRun Script Execution

```bash
# From alias
alias co="dr git/branch/co"

# Direct call
dr git/branch/co feature-branch

# With flags
dr dgsl/genAiSummary -p gemini -f urls.txt
```

### Helper Loading

```bash
# Load single helper
loadHelpers global/colors

# Load multiple helpers
loadHelpers global/colors
loadHelpers global/logging
loadHelpers git/git
```

### Conditional Execution

```bash
# Shell-specific
[[ $CURRENT_SHELL == "bash" ]] && { ... }
[[ $CURRENT_SHELL == "zsh" ]] && { ... }

# Command availability
if command -v brew >/dev/null 2>&1; then
  # brew is installed
fi

# Git repository check
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not a git repository"
  exit 1
fi
```

---

## 6. Migration Checklist

When migrating files to DotRun format:

**Aliases:**

- [ ] Rename to `NN-category.aliases` format
- [ ] Add standard header comment
- [ ] Convert to `alias name="command"` format
- [ ] Replace script calls with `dr category/script`
- [ ] Add shell-specific blocks if needed

**Configs:**

- [ ] Rename to `NN.category.config` format
- [ ] Add standard header comment
- [ ] Use `export` for all environment variables
- [ ] Add conditional blocks for tool availability
- [ ] Move sensitive data to `00.secure/` folder

**Scripts:**

- [ ] Create category directory if needed
- [ ] Rename to `scriptName.sh`
- [ ] Add triple DOC blocks with description and usage
- [ ] Add `set -euo pipefail`
- [ ] Add `DR_LOAD_HELPERS` check and `loadHelpers` calls
- [ ] Wrap main logic in `main()` function
- [ ] Add argument parsing if needed
- [ ] Add `showHelp()` function for complex scripts
- [ ] Call `main "$@"` at the end

---

## 7. Template Files

DotRun provides a script template at:

```
/home/user/dotrun/core/shared/dotrun/core/templates/script.sh
```

This template includes:

- Standard triple DOC blocks
- `set -euo pipefail`
- `DR_LOAD_HELPERS` setup
- Helper loading pattern
- Basic `main()` function structure

Use this as a starting point for new scripts.

---

## 8. Best Practices

1. **Documentation:** Always include comprehensive DOC blocks with usage examples
2. **Error Handling:** Use `set -euo pipefail` and validate inputs
3. **Helper Functions:** Extract reusable logic to helpers in `~/.config/dotrun/helpers/`
4. **Naming:** Use descriptive names that indicate purpose
5. **Load Order:** Choose numeric prefixes thoughtfully based on dependencies
6. **Shellcheck:** Address shellcheck warnings or add disable directives with justification
7. **Permissions:** Secure configs should have restrictive permissions (600)
8. **Testing:** Test scripts in isolation before integrating into DotRun

---

## 9. Common Patterns

### Git Commands

```bash
# Get current branch
git_current_branch=$(git rev-parse --abbrev-ref HEAD)

# Check if branch exists locally
git show-ref --verify --quiet "refs/heads/$branch"

# Check if branch exists on origin
git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
```

### File Operations

```bash
# Create directory if needed
mkdir -p "$OUTPUT_DIR"

# Check file size
FILE_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)

# Read file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue  # Skip empty/comments
  processLine "$line"
done < "$input_file"
```

### Argument Parsing with Options

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      showHelp
      exit 0
      ;;
    -f|--file)
      file="$2"
      shift 2
      ;;
    -o|--option)
      option="$2"
      shift 2
      ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      showHelp
      exit 1
      ;;
    *)
      positional_args+=("$1")
      shift
      ;;
  esac
done
```

---

## Additional Resources

- **Helper functions:** `~/.config/dotrun/helpers/`
- **Existing scripts:** `~/.config/dotrun/scripts/`
- **DotRun core:** `/home/user/dotrun/core/`
- **Documentation:** Use `dr --help` and `dr {category} --help`
