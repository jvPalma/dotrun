# Script Migration Reference

Migrate existing standalone shell scripts to DotRun's managed script system with helper integration. Transforms isolated scripts into integrated DotRun commands with discoverability, auto-completion, standardized error handling, and access to DotRun's helper library.

---

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [Phase 1: Script Discovery](#phase-1-script-discovery)
3. [Phase 2: Script Analysis](#phase-2-script-analysis)
4. [Phase 3: Interactive Selection](#phase-3-interactive-selection)
5. [Phase 4: Migration Execution](#phase-4-migration-execution)
6. [Phase 5: Enhancement Details](#phase-5-enhancement-details)
7. [Phase 6: Testing & Verification](#phase-6-testing--verification)
8. [Phase 7: Documentation & Cleanup](#phase-7-documentation--cleanup)
9. [Anti-Pattern Reference](#anti-pattern-reference)
10. [Shell Conversion Notes](#shell-conversion-notes)

---

## Workflow Overview

```
Phase 1: DISCOVERY → Phase 2: ANALYSIS → Phase 3: SELECTION → Phase 4: MIGRATION → Phase 5: ENHANCEMENT → Phase 6: TESTING → Phase 7: DOCUMENTATION
```

---

## Phase 1: Script Discovery

### Default Scan Locations

| Location        | Priority | Notes                   |
| --------------- | -------- | ----------------------- |
| `~/scripts/`    | High     | Common personal scripts |
| `~/bin/`        | High     | User binary directory   |
| `~/.local/bin/` | Medium   | XDG standard location   |
| `./scripts/`    | Medium   | Project-local scripts   |
| `~/.scripts/`   | Low      | Alternative personal    |

### Discovery Steps

1. Accept explicit paths from user OR scan default locations
2. For each location, find files matching:
   - Has `.sh`, `.bash`, or `.zsh` extension
   - OR has shell shebang (`#!/bin/bash`, `#!/usr/bin/env bash`, etc.)
   - AND is executable
3. Exclude:
   - Files already in `~/.config/dotrun/scripts/`
   - Hidden files (`.dotfile`)
   - Non-shell scripts (Python, Node, Ruby)
4. Collect metadata for each: path, size, shell type, detected description

### User Interaction

```
Discovered scripts to migrate:

Location: ~/scripts/ (scanning...)

  [1] git-cleanup.sh (2.4 KB) - bash
      Suggested namespace: git/cleanup

  [2] backup-db.sh (1.1 KB) - bash
      Suggested namespace: backup/database

  [3] deploy.zsh (1.5 KB) - zsh ⚠️
      Note: Uses zsh-specific features

Total: 3 scripts found

Which scripts should I analyze? (Enter numbers, "all", or provide path):
```

---

## Phase 2: Script Analysis

### Shell Detection Matrix

| Shell | Shebang Patterns                     | Migration Support                      |
| ----- | ------------------------------------ | -------------------------------------- |
| bash  | `#!/bin/bash`, `#!/usr/bin/env bash` | Full support                           |
| zsh   | `#!/bin/zsh`, `#!/usr/bin/env zsh`   | Convert if possible, flag zsh-specific |
| sh    | `#!/bin/sh`                          | Basic migration, warn about bashisms   |
| fish  | `#!/usr/bin/env fish`                | Skip - recommend manual migration      |

### Pattern Detection Rules

For each script, detect these patterns and map to DotRun helpers:

#### Color Codes → `global/colors`

```bash
# DETECT (legacy patterns):
echo -e "\033[31mError\033[0m" # Raw ANSI red
echo -e "\e[32mSuccess\e[0m"   # Escape sequences
RED='\033[0;31m'
NC='\033[0m' # Manual color vars
$'\e[31m'    # ANSI in $'' syntax
tput setaf 1 # tput color calls

# REPLACE WITH:
loadHelpers global/colors
echo -e "${RED}Error${NC}"
echo -e "${GREEN}Success${NC}"
```

#### Logging → `global/logging`

```bash
# DETECT (legacy patterns):
echo "Error: something failed"
echo "[ERROR] Failed to connect"
echo "[INFO] Processing..."
echo "[WARNING] Deprecated"
printf "[ERROR] %s\n" "$msg" >&2

# REPLACE WITH:
loadHelpers global/logging
log_error "something failed"
log_info "Processing..."
log_warning "Deprecated"
```

#### Tool Validation → `global/pkg`

```bash
# DETECT (legacy patterns):
if ! command -v jq &>/dev/null; then
  echo "jq is not installed"
  exit 1
fi
command -v git >/dev/null || {
  echo "git required"
  exit 1
}
which docker || exit 1

# REPLACE WITH:
loadHelpers global/pkg
validatePkg jq
validatePkg git
validatePkg docker
```

#### Git Operations → `git/git`

```bash
# DETECT (legacy patterns):
git rev-parse --show-toplevel
git symbolic-ref --short HEAD
branch=$(git rev-parse --abbrev-ref HEAD)
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'

# REPLACE WITH:
loadHelpers git/git
root=$(git_repo_root)
branch=$(git_current_branch)
default=$(git_default_branch)
```

#### Path Exclusions → `utils/filters`

```bash
# DETECT (legacy patterns):
if [[ "$path" == *"node_modules"* ]]; then continue; fi
[[ "$dir" == *".git"* ]] && skip
[[ "$file" == "package-lock.json" ]] && continue

# REPLACE WITH:
loadHelpers utils/filters
SCAN_ROOT="$project_root"
if gpt_should_exclude "$abs_path"; then
  continue
fi
```

### Issue Detection

| Issue Type            | Detection                               | Severity | Auto-fixable |
| --------------------- | --------------------------------------- | -------- | ------------ |
| Missing shebang       | No `#!` on line 1                       | Error    | Yes          |
| No error handling     | Missing `set -e` or `set -euo pipefail` | Warning  | Yes          |
| Missing documentation | No `### DOC` markers                    | Warning  | Yes          |
| Hardcoded paths       | `/home/username/`, unquoted `~/`        | Info     | Sometimes    |
| Inconsistent logging  | Mixed echo/printf styles                | Info     | Yes          |

---

## Phase 3: Interactive Selection

### Display Format

```
=== Script Migration Plan ===

Source: ~/scripts/ (analyzed 5 scripts)

--- SCRIPTS TO MIGRATE ---

1. [ ] git-cleanup.sh (2.4 KB)
       Shell: bash | Target: git/cleanup
       Issues: Missing error handling, Missing docs
       Suggestions:
         • Use global/colors (detected 3 color codes)
         • Use global/pkg (detected tool validation)
       [BASIC] [ENHANCED] [SKIP]

2. [+] backup-db.sh (1.1 KB) - ENHANCED SELECTED
       Shell: bash | Target: backup/database
       Issues: None
       Suggestions:
         • Use global/logging (detected 5 echo statements)
       [CHANGE SELECTION]

3. [-] deploy.zsh (1.5 KB) - SKIPPED
       Shell: zsh ⚠️ Uses glob qualifiers
       Recommendation: Manual migration required
       [FORCE MIGRATE]

--- SUMMARY ---
Basic: 0 | Enhanced: 1 | Skipped: 1 | Remaining: 1

Options:
  [A] Accept defaults and proceed
  [B] Basic migrate all remaining
  [E] Enhanced migrate all remaining
  [I] Item-by-item selection
  [Q] Quit
```

### Migration Modes

| Mode         | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| **BASIC**    | Copy script, add DotRun header, preserve content             |
| **ENHANCED** | Basic + add error handling, integrate helpers, add structure |
| **SKIP**     | Don't migrate, leave original unchanged                      |

---

## Phase 4: Migration Execution

### Pre-Migration Safety

1. **Backup originals** (optional, ask user):

   ```bash
   mkdir -p ~/.config/dotrun/.backups/scripts/$(date +%Y%m%d-%H%M%S)
   cp "$original" "$backup_dir/"
   ```

2. **Validate target paths** - Ensure no overwrites without confirmation

3. **Dry run available** - Preview all changes before execution

### Basic Migration Template

```bash
#!/usr/bin/env bash
### DOC
# {script_name} - {detected_or_prompted_description}
### DOC
#
# Migrated from: {original_path}
# Migration date: {date}
#
# Usage:
#   dr {namespace/name} [args]
#
### DOC

# ============================================
# ORIGINAL SCRIPT CONTENT BELOW
# ============================================

{original_content}
```

### Enhanced Migration Template

```bash
#!/usr/bin/env bash
### DOC
# {script_name} - {description}
### DOC
#
# Migrated from: {original_path}
# Migration date: {date}
#
# Usage:
#   dr {namespace/name} [options] [args]
#
# Options:
#   -h, --help    Show this help
#   -v, --verbose Enable verbose output
#
# Examples:
#   dr {namespace/name}
#   dr {namespace/name} --verbose
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers
loadHelpers global/colors
loadHelpers global/logging
{additional_helpers}

# ============================================
# CONFIGURATION
# ============================================

VERBOSE="${VERBOSE:-false}"

# ============================================
# FUNCTIONS
# ============================================

show_help() {
  grep -A 100 '### DOC' "${BASH_SOURCE[0]}" | grep -B 100 '### DOC' | grep -v '### DOC' | tail -n +2
  exit 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help) show_help ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      *) break ;;
    esac
  done
}

# ============================================
# MAIN LOGIC
# ============================================

main() {
  parse_args "$@"

  log_info "Starting {script_name}..."

  {transformed_original_content}

  log_success "{script_name} completed"
}

# ============================================
# CLEANUP
# ============================================

cleanup() {
  # Add cleanup logic if needed
  :
}

trap cleanup EXIT

# Execute
main "$@"
```

---

## Phase 5: Enhancement Details

### Helper Integration Process

When enhanced migration is selected:

1. **Add loadHelpers boilerplate**:

   ```bash
   [[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
   ```

2. **Replace detected patterns** with helper calls (see Phase 2 mappings)

3. **Add structure**:
   - Wrap logic in `main()` function
   - Add argument parsing if args detected
   - Add cleanup trap if file operations detected

### Pattern Transformation Examples

#### Before & After: Color Codes

**Before:**

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${RED}Error: $msg${NC}"
echo -e "${GREEN}Success${NC}"
```

**After:**

```bash
loadHelpers global/colors
echo -e "${RED}Error: $msg${NC}"
echo -e "${GREEN}Success${NC}"
```

#### Before & After: Logging

**Before:**

```bash
echo "[INFO] Starting process..."
echo "[ERROR] Failed to connect" >&2
echo "[WARN] Retrying..."
```

**After:**

```bash
loadHelpers global/logging
log_info "Starting process..."
log_error "Failed to connect"
log_warning "Retrying..."
```

#### Before & After: Tool Validation

**Before:**

```bash
if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed"
  echo "Install with: brew install jq"
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "Error: git is required"
  exit 1
fi
```

**After:**

```bash
loadHelpers global/pkg
validatePkg jq
validatePkg git
```

#### Before & After: Git Operations

**Before:**

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

if git merge-base --is-ancestor "$branch" "$DEFAULT_BRANCH"; then
  echo "Branch is merged"
fi
```

**After:**

```bash
loadHelpers git/git
REPO_ROOT=$(git_repo_root)
CURRENT_BRANCH=$(git_current_branch)
DEFAULT_BRANCH=$(git_default_branch)

if is_branch_merged "$branch" "$DEFAULT_BRANCH"; then
  log_info "Branch is merged"
fi
```

---

## Phase 6: Testing & Verification

### Post-Migration Checks

1. **Syntax validation**:

   ```bash
   for f in ~/.config/dotrun/scripts/**/*.sh; do
     bash -n "$f" || echo "Syntax error in $f"
   done
   ```

2. **Helper loading test**:

   ```bash
   # Verify helpers load without error
   (source "$f" && loadHelpers global/colors) 2>/dev/null || echo "Helper issue in $f"
   ```

3. **Execution test** (if safe):
   ```bash
   dr {namespace/name} --help # Should show documentation
   ```

### Verification Checklist

- [ ] Script executes without syntax errors
- [ ] `dr -l` shows the new script
- [ ] `dr help {name}` shows documentation
- [ ] Original functionality preserved
- [ ] Helpers load successfully

---

## Phase 7: Documentation & Cleanup

### Migration Report

```
=== Migration Summary ===

Scripts migrated:
  ✅ git/cleanup (from ~/scripts/git-cleanup.sh)
     Mode: Enhanced | Helpers: global/colors, global/pkg

  ✅ backup/database (from ~/scripts/backup-db.sh)
     Mode: Enhanced | Helpers: global/logging

  ⏭️ deploy.zsh - Skipped (zsh-specific features)

Files created:
  ~/.config/dotrun/scripts/git/cleanup.sh
  ~/.config/dotrun/scripts/backup/database.sh

Backup location (if enabled):
  ~/.config/dotrun/.backups/scripts/20260128-143052/

IMPORTANT: Your original scripts were NOT modified.

Next steps:
1. Test migrated scripts: dr git/cleanup --help
2. Remove originals (optional): rm ~/scripts/git-cleanup.sh
3. Reload shell: source ~/.drrc OR start new terminal
```

---

## Anti-Pattern Reference

| Anti-Pattern      | Detection Regex                     | Helper            | Replacement            |
| ----------------- | ----------------------------------- | ----------------- | ---------------------- |
| Raw ANSI codes    | `\033\[`, `\e\[`, `tput setaf`      | `global/colors`   | Color variables        |
| Echo logging      | `echo.*\[(ERROR\|INFO\|WARN)\]`     | `global/logging`  | `log_*()` functions    |
| Manual tool check | `command -v.*\|\|.*exit`            | `global/pkg`      | `validatePkg()`        |
| Git rev-parse     | `git rev-parse`, `git symbolic-ref` | `git/git`         | Helper functions       |
| Path exclusions   | `*node_modules*`, `*.git*`          | `utils/filters`   | `gpt_should_exclude()` |
| Shellcheck calls  | `shellcheck`                        | `validation/lint` | `run_shell_lint()`     |

---

## Shell Conversion Notes

### Zsh to Bash Considerations

| Zsh Feature            | Bash Equivalent                 | Notes                   |
| ---------------------- | ------------------------------- | ----------------------- |
| `${(f)var}`            | `echo "$var"`                   | Line splitting          |
| `${array[@]:1}`        | `${array[@]:1}`                 | Same syntax             |
| `**/` glob             | `**/*` with `shopt -s globstar` | Requires bash 4+        |
| `setopt`               | `shopt -s`                      | Different option names  |
| Glob qualifiers `*(.)` | N/A                             | Manual filtering needed |

### Scripts to Skip

- Heavy zsh-specific syntax (glob qualifiers, zparseopts)
- Fish shell scripts (entirely different syntax)
- Scripts with non-shell interpreters embedded

---

## Error Recovery

```
=== Migration Recovery ===

If something went wrong:

1. Your original scripts are untouched at their original locations

2. If backup was enabled:
   ~/.config/dotrun/.backups/scripts/20260128-143052/

3. To remove a migrated script:
   dr rm {namespace/name}

4. To restore from backup:
   cp ~/.config/dotrun/.backups/scripts/20260128-143052/script.sh ~/scripts/
```
