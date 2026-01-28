# DotRun CLI - System Architecture

## Table of Contents

1. [Directory Structure](#directory-structure)
2. [File Locations](#file-locations)
3. [Shell Integration](#shell-integration)
4. [Script Execution Flow](#script-execution-flow)
5. [Helper System](#helper-system)
6. [Collections Architecture](#collections-architecture)
7. [Documentation System](#documentation-system)

---

## Directory Structure

### User Configuration (`~/.config/dotrun/`)

```
~/.config/dotrun/
├── scripts/              # User scripts (.sh)
│   ├── deploy.sh
│   ├── git/
│   │   ├── cleanup.sh
│   │   └── sync.sh
│   └── devops/
│       └── ci/
│           └── build.sh
├── aliases/              # Alias files (.aliases)
│   ├── 01-linux.aliases
│   ├── 02-git.aliases
│   └── docker/
│       └── compose.aliases
├── configs/              # Config files (.config)
│   ├── 01-paths.config
│   └── api/
│       └── credentials.config
├── helpers/              # Shared helper modules (.sh)
│   ├── global/
│   │   ├── colors.sh
│   │   └── pkg.sh
│   └── git/
│       └── git.sh
└── collections/          # Cloned collection repos
    └── my-team-scripts/
        ├── .git/
        ├── dotrun.collection.yml
        └── scripts/
```

### System Files (`~/.local/share/dotrun/`)

```
~/.local/share/dotrun/
├── core/
│   ├── aliases.sh        # Alias management functions
│   ├── config.sh         # Config management functions
│   ├── collections.sh    # Collection management (~3,366 lines)
│   └── templates/
│       └── script.sh     # New script template
├── helpers/
│   └── loadHelpers.sh    # Helper loading system
├── shell/
│   ├── bash/
│   │   ├── aliases.sh
│   │   ├── configs.sh
│   │   ├── dr_completion.bash
│   │   └── dr_completion_ble.sh
│   ├── zsh/
│   │   ├── aliases.sh
│   │   ├── configs.sh
│   │   └── dr_completion.zsh
│   └── fish/
│       ├── aliases.sh
│       ├── configs.sh
│       └── dr_completion.fish
├── .dr_config_loader     # Universal config loader
└── collections.conf      # Collection metadata (INI)
```

### Main Entry Point

- **CLI**: `~/.local/bin/dr` (symlink to main script)
- **Source**: `~/.local/share/dotrun/dr` (~1,304 lines)

---

## File Locations

| Item                | Location                                 | Purpose             |
| ------------------- | ---------------------------------------- | ------------------- |
| Main CLI            | `~/.local/bin/dr`                        | Entry point command |
| Scripts             | `~/.config/dotrun/scripts/`              | User scripts        |
| Aliases             | `~/.config/dotrun/aliases/`              | Shell aliases       |
| Configs             | `~/.config/dotrun/configs/`              | Environment exports |
| Helpers             | `~/.config/dotrun/helpers/`              | Reusable modules    |
| Collections         | `~/.config/dotrun/collections/`          | Cloned repos        |
| Shell Init          | `~/.drrc`                                | Shell integration   |
| Collection Metadata | `~/.local/share/dotrun/collections.conf` | INI tracking        |

---

## Shell Integration

### Initialization Chain

```
~/.bashrc / ~/.zshrc / ~/.config/fish/config.fish
    ↓
~/.drrc (sources all below)
    ↓
~/.local/share/dotrun/.dr_config_loader
    ↓
Shell-specific loaders:
├── shell/<shell>/configs.sh  → Sources all *.config files
├── shell/<shell>/aliases.sh  → Sources all *.aliases files
└── shell/<shell>/dr_completion.*  → Tab completion
```

### Load Order

1. System defaults (set in `dr` script)
2. `~/.drrc` exports `DR_CONFIG` and `DR_LOAD_HELPERS`
3. `.dr_config_loader` detects shell
4. Config files loaded (alphabetically: `01-*` before `02-*`)
5. Alias files loaded (alphabetically)
6. Shell completion registered

### Reload Configuration

```bash
dr -r                  # Shows reload instructions
source ~/.drrc         # Actually reload
```

---

## Script Execution Flow

### Command Dispatch

```
User: dr script-name args...
    ↓
Primary Router (case $1):
├── -l/-L     → list_scripts()
├── -r        → reload instructions
├── -s        → scripts namespace
├── -a        → aliases namespace
├── -c        → config namespace
├── -col      → collections namespace
├── -v/-h     → version/help
└── *         → run_script()
```

### Script Discovery: `find_script_file()`

Two-tier search strategy:

1. **Explicit path**: If contains `/`, check `$BIN_DIR/path.sh` directly
2. **Basename fallback**: Search entire `$BIN_DIR` recursively

```bash
dr foo/bar   # First: ~/.config/dotrun/scripts/foo/bar.sh
             # Fallback: find -name "bar.sh" anywhere

dr cleanup   # Search: find -name "cleanup.sh" in scripts/
```

### Script Execution Context

```bash
run_script() {
    export DR_CONFIG
    export DR_LOAD_HELPERS
    "$script_file" "$@"  # Execute with all args
}
```

Scripts receive:

- All arguments passed through
- `DR_CONFIG` pointing to config directory
- `DR_LOAD_HELPERS` for loading helper modules

---

## Helper System

### `loadHelpers` Function

Location: `~/.local/share/dotrun/helpers/loadHelpers.sh`

**5-Level Pattern Matching:**

1. **Absolute path**: `/path/to/helper.sh`
2. **Exact path with .sh**: `gcp/workstation.sh`
3. **Path + auto extension**: `gcp/workstation` → `.sh` added
4. **Collection-prefixed**: `dotrun-anc/gcp/workstation`
5. **Filename only**: `workstation` (searches all helpers)

**Special**: `@collection-name` loads all helpers from collection

### Usage in Scripts

```bash
#!/usr/bin/env bash
# Enable helper loading
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load specific helper
loadHelpers global/colors

# Load by name (searches)
loadHelpers workstation

# Load all from collection
loadHelpers @my-collection

# Preview without loading
loadHelpers git/validation --list
```

### Safety Features

- Circular dependency protection (max depth: 10)
- Path canonicalization (prevents re-sourcing)
- Directory boundary checks
- Bash 3+ compatibility

---

## Collections Architecture

### Copy-Based Import

Collections use **copy** (not symlink) strategy:

- Users own imported files
- Can modify freely
- Updates use conflict resolution

### Hash Tracking

- SHA256 hashes (8-char) detect local modifications
- Stored in `collections.conf`
- Enables smart update detection

### Version Management

- Semantic versioning via Git tags
- `dr -col sync` checks for updates
- `dr -col update` applies with prompts

### Conflict Resolution Options

**Unmodified files**: Update, Diff, Skip
**Modified files**: Keep, Overwrite, Diff, Merge, Backup

### Collection Structure

```yaml
# dotrun.collection.yml
name: "team-scripts"
version: "1.0.0"
description: "Team automation"
author: "DevOps"
repository: "https://github.com/team/scripts.git"
```

```
collection/
├── dotrun.collection.yml
├── scripts/        # Imported to ~/.config/dotrun/scripts/
├── aliases/        # Imported to ~/.config/dotrun/aliases/
├── configs/        # Imported to ~/.config/dotrun/configs/
└── helpers/        # Imported to ~/.config/dotrun/helpers/
```

---

## Documentation System

### `### DOC` Markers

Scripts use triple-hash markers for documentation:

```bash
#!/usr/bin/env bash
### DOC
# One-line description (shown in dr -L)
### DOC
#
# Extended help (shown in dr help <name>)
#
# Usage:
#   dr script-name [args]
#
### DOC
```

### Extraction Logic

- `dr -L`: Content between 1st and 2nd markers
- `dr help`: Content between 2nd and 3rd markers
- Fallback: Uses 1st-2nd if no 3rd marker

### Best Practices

- First block: Brief, scannable description
- Second block: Detailed usage, examples, requirements
- Keep descriptions actionable and concise
