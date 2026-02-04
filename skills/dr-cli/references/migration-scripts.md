# Script Migration

> Migrate standalone shell scripts to DotRun's managed system with helper integration.

## Quick Workflow

```
1. DISCOVER → Find scripts in ~/scripts/, ~/bin/, ~/.local/bin/
2. ANALYZE  → Detect shell, patterns, issues
3. SELECT   → Choose BASIC or ENHANCED mode
4. MIGRATE  → Transform and copy to DotRun
5. TEST     → Verify functionality
```

---

## Phase 1: Discovery

**Scan locations** (priority order):

1. `~/scripts/` - Personal scripts
2. `~/bin/` - User binaries
3. `~/.local/bin/` - XDG location
4. `./scripts/` - Project-local

**Include if**: Has `.sh`/`.bash` extension OR shell shebang + executable

**Exclude**: Already in `~/.config/dotrun/scripts/`, hidden files, non-shell

---

## Phase 2: Pattern Detection

### Detect → Replace with Helpers

| Pattern                            | Helper           | Replacement             |
| ---------------------------------- | ---------------- | ----------------------- |
| `\033[31m`, `\e[32m`, `tput setaf` | `global/colors`  | `${RED}`, `${GREEN}`    |
| `echo "[ERROR]"`, `echo "[INFO]"`  | `global/logging` | `log_error`, `log_info` |
| `command -v X \|\| exit 1`         | `global/pkg`     | `validatePkg X`         |
| `git rev-parse --show-toplevel`    | `git/git`        | `git_repo_root`         |
| `git symbolic-ref --short HEAD`    | `git/git`        | `git_current_branch`    |

### Issue Detection

| Issue                              | Severity | Auto-fix  |
| ---------------------------------- | -------- | --------- |
| Missing shebang                    | Error    | Yes       |
| No `set -e` or `set -euo pipefail` | Warning  | Yes       |
| Missing `### DOC` markers          | Warning  | Yes       |
| Hardcoded `/home/username/`        | Info     | Sometimes |

---

## Phase 3: Migration Modes

### BASIC Mode

Copy script, add DotRun header, preserve content:

```bash
#!/usr/bin/env bash
### DOC
# script-name - Migrated script
### DOC
# Migrated from: ~/scripts/original.sh
### DOC

# ===== ORIGINAL CONTENT =====
{original_content}
```

### ENHANCED Mode

Add error handling, helpers, structure:

```bash
#!/usr/bin/env bash
### DOC
# script-name - Description
### DOC
# Migrated from: ~/scripts/original.sh
# Usage: dr category/name [args]
### DOC

set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/colors
loadHelpers global/logging

main() {
  log_info "Starting..."
  {transformed_content}
  log_success "Done"
}

main "$@"
```

---

## Phase 4: Transformation Examples

### Colors

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

## Phase 5: Verification

```bash
# Syntax check
bash -n ~/.config/dotrun/scripts/path/to/script.sh

# Helper loading test
(source "$script" && loadHelpers global/colors) 2>/dev/null

# Execution test
dr category/name --help
```

**Checklist:**

- [ ] Script runs without syntax errors
- [ ] `dr -L` shows new script
- [ ] `dr help name` shows documentation
- [ ] Original functionality preserved

---

## Shell Conversion

| Zsh Feature            | Bash Equivalent                 |
| ---------------------- | ------------------------------- |
| `${(f)var}`            | `echo "$var"`                   |
| `**/` glob             | `**/*` with `shopt -s globstar` |
| Glob qualifiers `*(.)` | Manual filtering                |

**Skip migration** for: Heavy zsh syntax, Fish scripts, scripts with embedded non-shell interpreters.
