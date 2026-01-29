# Shell Config Migration Reference

Migrate shell configuration files (.bashrc, .zshrc, config.fish) to DotRun's structured alias and config system. Provides interactive, safe migration with diff previews, categorization suggestions, and backup mechanisms.

---

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [Phase 1: Shell Detection](#phase-1-shell-detection)
3. [Phase 2: Parsing & Categorization](#phase-2-parsing--categorization)
4. [Phase 3: Interactive Plan Review](#phase-3-interactive-plan-review)
5. [Phase 4: Migration Execution](#phase-4-migration-execution)
6. [Phase 5: Verification & Cleanup](#phase-5-verification--cleanup)
7. [DotRun File Format Reference](#dotrun-file-format-reference)
8. [Fish Shell Conversion](#fish-shell-conversion)
9. [Error Recovery](#error-recovery)

---

## Workflow Overview

```
Phase 1: DETECTION → Phase 2: PARSING & CATEGORIZATION → Phase 3: TODO LIST GENERATION (Interactive) → Phase 4: MIGRATION EXECUTION → Phase 5: VERIFICATION & CLEANUP
```

---

## Phase 1: Shell Detection

### File Location Matrix

| Shell | Primary Config               | Secondary Configs                                                 |
| ----- | ---------------------------- | ----------------------------------------------------------------- |
| Bash  | `~/.bashrc`                  | `~/.bash_profile`, `~/.bash_aliases`, `~/.profile`                |
| Zsh   | `~/.zshrc`                   | `~/.zprofile`, `~/.zshenv`, `~/.zlogin`                           |
| Fish  | `~/.config/fish/config.fish` | `~/.config/fish/conf.d/*.fish`, `~/.config/fish/functions/*.fish` |

### Detection Steps

1. Identify shell from `$SHELL` environment variable
2. Check if primary config exists
3. Scan for secondary configs
4. Report findings and let user confirm which files to migrate

### User Interaction

```
Detected shell configuration files:

  [1] ~/.zshrc (2,340 lines) - Primary
  [2] ~/.zprofile (45 lines) - Secondary
  [3] ~/.bash_profile (120 lines) - Legacy

Which files should I analyze? (Enter numbers, e.g., "1,2" or "all"):
```

---

## Phase 2: Parsing & Categorization

### Pattern Detection

#### Alias Patterns (Bash/Zsh)

```regex
# Single-quoted alias
^alias\s+([a-zA-Z_][a-zA-Z0-9_-]*)='([^']*(?:'\\'[^']*)*)'

# Double-quoted alias
^alias\s+([a-zA-Z_][a-zA-Z0-9_-]*)="([^"]*(?:\\.[^"]*)*)"

# Fish abbreviation
^abbr\s+(--add\s+)?(-g\s+)?([a-zA-Z_][a-zA-Z0-9_-]*)\s+(.+)$
```

#### Export Patterns (Bash/Zsh)

```regex
# Standard export with quotes
^export\s+([A-Z_][A-Za-z0-9_]*)=["'](.*)["']

# PATH modification patterns
^export\s+PATH=["']?\$PATH:(.+?)["']?$
^export\s+PATH=["']?(.+?):\$PATH["']?$
```

#### Fish Exports

```regex
# Fish global export
^set\s+-gx\s+([A-Z_][A-Za-z0-9_]*)\s+(.+)$

# Fish universal export
^set\s+-Ux\s+([A-Z_][A-Za-z0-9_]*)\s+(.+)$
```

#### Function Patterns

```regex
# Bash/Zsh function styles
^function\s+([a-zA-Z_][a-zA-Z0-9_-]*)\s*\(\s*\)\s*\{
^([a-zA-Z_][a-zA-Z0-9_-]*)\s*\(\s*\)\s*\{

# Fish function
^function\s+([a-zA-Z_][a-zA-Z0-9_-]*)(?:\s+--description\s+['"]([^'"]+)['"])?
```

### Automatic Category Detection

#### Alias Categories (by command prefix/content)

| Prefix Pattern            | Category   | DotRun File             |
| ------------------------- | ---------- | ----------------------- |
| `g*`, `git*`              | Git        | `05-git.aliases`        |
| `d*`, `docker*`, `dc*`    | Docker     | `10-docker.aliases`     |
| `k*`, `kubectl*`, `kube*` | Kubernetes | `15-kubernetes.aliases` |
| `..`, `cd*`, `ls*`, `ll*` | Navigation | `01-navigation.aliases` |
| `npm*`, `yarn*`, `pnpm*`  | Node       | `20-node.aliases`       |
| `py*`, `python*`, `pip*`  | Python     | `25-python.aliases`     |
| Other                     | Misc       | `90-misc.aliases`       |

#### Export Categories (by variable name)

| Variable Pattern                 | Category    | DotRun File             |
| -------------------------------- | ----------- | ----------------------- |
| `PATH`, `*_PATH`, `*_BIN`        | Paths       | `01-paths.config`       |
| `XDG_*`                          | XDG         | `02-xdg.config`         |
| `*_TOKEN`, `*_KEY`, `*_SECRET`   | API/Secrets | `05-api.config`         |
| `EDITOR`, `VISUAL`, `PAGER`      | Editor      | `03-editor.config`      |
| `GO*`, `CARGO*`, `NPM*`, `NODE*` | Development | `10-development.config` |
| `AWS_*`, `GCP_*`, `AZURE_*`      | Cloud       | `20-cloud.config`       |
| Other                            | Misc        | `80-misc.config`        |

---

## Phase 3: Interactive Plan Review

### Display Format

```
=== Shell Config Migration Plan ===

Source: ~/.zshrc (analyzed 2,340 lines)
Found: 45 aliases, 23 exports, 8 functions, 5 source statements

--- ALIASES (45 items) ---

Category: Git (12 items) → 05-git.aliases
  [MIGRATE] alias gs='git status -sb'
  [MIGRATE] alias gc='git commit -m'
  [REVIEW]  alias gcb='git checkout -b'  ⚠️ Similar to existing 'gcb' in DotRun

Category: Docker (8 items) → 10-docker.aliases
  [MIGRATE] alias d='docker'
  [SKIP]    alias dps='docker ps'  (Already exists in DotRun)

--- EXPORTS (23 items) ---

Category: Paths (5 items) → 01-paths.config
  [MIGRATE] export PATH="$HOME/.local/bin:$PATH"
  [REVIEW]  export PATH="$HOME/go/bin:$PATH"  ⚠️ Go also handled in 10-development.config

Category: API Keys (4 items) → 05-api.config [SENSITIVE]
  [MIGRATE] export GITHUB_TOKEN="ghp_..."
  [REVIEW]  export OPENAI_API_KEY="sk-..."  ⚠️ Consider secrets manager

--- FUNCTIONS (8 items) ---

  [REVIEW]  mkcd() {...}  → Suggest: scripts/utils/mkcd.sh
  [SKIP]    __git_prompt() {...}  (Internal function)

--- SOURCE STATEMENTS (5 items) ---

  [NOTE] source "$HOME/.nvm/nvm.sh"  → Add to 10-development.config
```

### User Review Options

```
Options:
  [1] Accept all defaults and proceed
  [2] Review item-by-item (recommended for first migration)
  [3] Change category for a group
  [4] Mark items to SKIP
  [5] Export plan as file (review offline)
  [6] Abort migration
```

---

## Phase 4: Migration Execution

### Pre-Migration Safety

1. **Backup existing DotRun files**

   ```bash
   mkdir -p ~/.config/dotrun/.backups/$(date +%Y%m%d-%H%M%S)
   cp -r ~/.config/dotrun/aliases/* ~/.config/dotrun/.backups/.../
   cp -r ~/.config/dotrun/configs/* ~/.config/dotrun/.backups/.../
   ```

2. **Validate no destructive overwrites** - Show diff preview for existing files
3. **Dry run mode available** - Preview all changes before execution

### DotRun File Templates

#### Alias File Template

```bash
#!/usr/bin/env bash
# DotRun Aliases - {{CATEGORY}}
# Migrated from: {{SOURCE_FILE}} on {{DATE}}
#
# Category: {{CATEGORY_NAME}}
# Items: {{ITEM_COUNT}}

alias name='command'
```

#### Config File Template

```bash
#!/usr/bin/env bash
# DotRun Configuration - {{CATEGORY}}
# Migrated from: {{SOURCE_FILE}} on {{DATE}}

export VAR="value"

# External tool initialization
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
```

#### Function → Script Conversion Template

```bash
#!/usr/bin/env bash
### DOC
# {{FUNCTION_NAME}} - Migrated shell function
### DOC
#
# Migrated from: {{SOURCE_FILE}} line {{LINE_NUMBER}}
# Usage: dr {{SCRIPT_PATH}} [args]
### DOC

set -euo pipefail

# Load loadHelpers function
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

{{FUNCTION_BODY}}

main "$@"
```

### Conflict Resolution

When a target file exists, offer:

- **[O]verwrite** - Replace existing file
- **[R]ename** - Auto-increment: `file.aliases` → `file-2.aliases`
- **[S]kip** - Leave existing, skip import
- **[M]erge** - Append to existing file (aliases only)

---

## Phase 5: Verification & Cleanup

### Post-Migration Checks

1. **Syntax validation**

   ```bash
   for f in ~/.config/dotrun/aliases/*.aliases; do
     bash -n "$f" || echo "Syntax error in $f"
   done
   ```

2. **Reload and test**

   ```
   To apply changes:
   - Start a new terminal session, OR
   - Run 'dr reload' or 'source ~/.drrc'

   Quick verification:
     $ alias gs    # Should show migrated alias
   ```

### Migration Report

```
=== Migration Summary ===

Files created:
  ~/.config/dotrun/aliases/05-git.aliases (12 aliases)
  ~/.config/dotrun/aliases/10-docker.aliases (8 aliases)
  ~/.config/dotrun/configs/01-paths.config (5 exports)

Scripts suggested (not auto-created):
  scripts/utils/mkcd.sh (from function mkcd)

Items skipped: 15
Backup location: ~/.config/dotrun/.backups/20260128-143052/

IMPORTANT: Your original ~/.zshrc was NOT modified.
```

---

## DotRun File Format Reference

### Alias Files

- **Location**: `~/.config/dotrun/aliases/`
- **Extension**: `.aliases`
- **Naming**: `NN-category.aliases` (NN = load order: 01-99)
- **Format**: Standard bash `alias name='command'` syntax
- **Load order**: Alphabetical (use NN prefix to control)

### Config Files

- **Location**: `~/.config/dotrun/configs/`
- **Extension**: `.config`
- **Naming**: `NN-category.config`
- **Format**: Standard bash `export VAR="value"` syntax

---

## Migration Mapping Table

| Source Type        | DotRun Target               | File Extension |
| ------------------ | --------------------------- | -------------- |
| alias              | `~/.config/dotrun/aliases/` | `.aliases`     |
| export             | `~/.config/dotrun/configs/` | `.config`      |
| function (simple)  | Convert to alias            | `.aliases`     |
| function (complex) | `~/.config/dotrun/scripts/` | `.sh`          |
| source (config)    | Migrate contents            | varies         |
| eval (tool init)   | Document as dependency      | N/A            |
| PS1/PROMPT         | Do not migrate              | N/A            |
| shopt/setopt       | Do not migrate              | N/A            |

---

## Fish Shell Conversion

Fish syntax must be converted to bash format for DotRun:

| Fish Syntax               | Bash Equivalent             |
| ------------------------- | --------------------------- |
| `abbr gc 'git commit'`    | `alias gc='git commit'`     |
| `set -gx API_KEY "value"` | `export API_KEY="value"`    |
| `set -Ux VAR "value"`     | `export VAR="value"`        |
| `fish_add_path /path`     | `export PATH="/path:$PATH"` |

---

## Error Recovery

```
=== Migration Recovery ===

1. Your original shell config is untouched at: ~/.zshrc

2. Backup of DotRun state before migration:
   ~/.config/dotrun/.backups/20260128-143052/

3. To restore previous DotRun state:
   cp -r ~/.config/dotrun/.backups/20260128-143052/* ~/.config/dotrun/
```
