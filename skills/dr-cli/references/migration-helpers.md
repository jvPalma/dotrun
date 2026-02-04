# Helper System Reference

> DotRun's reusable function library with pattern-based loading.

## Quick Start

```bash
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/colors
loadHelpers global/logging

log_info "Script started"
echo -e "${GREEN}Success!${NC}"
```

---

## Available Helpers

### Global (`global/`)

| Helper    | Functions                                                          | Purpose            |
| --------- | ------------------------------------------------------------------ | ------------------ |
| `colors`  | `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `BOLD`, `NC`             | Terminal colors    |
| `logging` | `log_info`, `log_error`, `log_warning`, `log_success`, `log_debug` | Structured logging |
| `pkg`     | `validatePkg()`, `detect_shell()`, `pkg_install_hint()`            | Package management |

### Git (`git/`)

| Helper   | Functions                                                         | Purpose        |
| -------- | ----------------------------------------------------------------- | -------------- |
| `git`    | `git_repo_root()`, `git_current_branch()`, `git_default_branch()` | Git operations |
| `git_pr` | `prNewDraft()`, `prDraftToOpen()`                                 | PR management  |

---

## loadHelpers Patterns

```bash
loadHelpers global/colors       # Exact path (recommended)
loadHelpers colors              # Filename only (searches all)
loadHelpers @my-collection      # All from collection
loadHelpers git/git --list      # Preview without loading
```

**Resolution order:**

1. Absolute path: `/full/path/to/helper.sh`
2. Exact path with extension: `global/colors.sh`
3. Path without extension: `global/colors`
4. Collection/path: `dotrun-anc/gcp/workstation`
5. Filename only: `colors`

---

## Migration Examples

### Color Codes

**Before:**

```bash
RED='\033[0;31m'
NC='\033[0m'
echo -e "${RED}Error${NC}"
```

**After:**

```bash
loadHelpers global/colors
echo -e "${RED}Error${NC}"
```

### Logging

**Before:**

```bash
echo "[INFO] Starting..."
echo "[ERROR] Failed" >&2
```

**After:**

```bash
loadHelpers global/logging
log_info "Starting..."
log_error "Failed"
```

### Tool Validation

**Before:**

```bash
if ! command -v jq &>/dev/null; then
  echo "jq required"; exit 1
fi
```

**After:**

```bash
loadHelpers global/pkg
validatePkg jq
```

### Git Operations

**Before:**

```bash
branch=$(git symbolic-ref --short HEAD)
root=$(git rev-parse --show-toplevel)
```

**After:**

```bash
loadHelpers git/git
branch=$(git_current_branch)
root=$(git_repo_root)
```

---

## Environment Variables

| Variable             | Default | Purpose                  |
| -------------------- | ------- | ------------------------ |
| `DR_LOAD_HELPERS`    | (auto)  | Path to `loadHelpers.sh` |
| `DR_HELPERS_VERBOSE` | `0`     | Enable verbose loading   |
| `DEBUG`              | `false` | Enable `log_debug()`     |
| `GIT_DEFAULT_BRANCH` | (auto)  | Override default branch  |

---

## Common Gotchas

```bash
# Wrong - fails if DR_LOAD_HELPERS not set
source "$DR_LOAD_HELPERS"

# Correct - conditional load
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
```

- Max loading depth: 10 (prevents circular dependencies)
- Helpers must be in `~/.config/dotrun/helpers/`
- Duplicate loads are automatically skipped

---

## Best Practices

1. Always use `set -euo pipefail`
2. Load helpers at script top
3. Use specific patterns when possible
4. Document helper dependencies in script header
