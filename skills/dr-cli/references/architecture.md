# DotRun CLI - System Architecture

> Load this when debugging, explaining internals, or troubleshooting.

## File Locations

| Type        | Location                        | Extension    |
| ----------- | ------------------------------- | ------------ |
| Scripts     | `~/.config/dotrun/scripts/`     | `.sh`        |
| Aliases     | `~/.config/dotrun/aliases/`     | `.aliases`   |
| Configs     | `~/.config/dotrun/configs/`     | `.config`    |
| Helpers     | `~/.config/dotrun/helpers/`     | `.sh`        |
| Collections | `~/.config/dotrun/collections/` | (git repos)  |
| CLI         | `~/.local/bin/dr`               | symlink      |
| Core        | `~/.local/share/dotrun/`        | system files |

---

## Directory Structure

```
~/.config/dotrun/
├── scripts/           # User scripts (.sh)
│   ├── deploy.sh
│   └── git/
│       └── cleanup.sh
├── aliases/           # Alias files (.aliases)
│   ├── 01-linux.aliases
│   └── docker/
├── configs/           # Config files (.config)
│   ├── 01-paths.config
│   └── api/
├── helpers/           # Shared modules (.sh)
│   └── global/
└── collections/       # Cloned repos
```

---

## Shell Integration

```
`~/.bashrc` / `~/.zshrc` / `~/.config/fish/config.fish`
    ↓
~/.drrc (sources all below)
    ↓
~/.local/share/dotrun/.dr_config_loader
    ↓
Shell-specific loaders:
├── configs.sh   → Sources *.config files
├── aliases.sh   → Sources *.aliases files
└── completion   → Tab completion
```

**Load order**: System defaults → `~/.drrc` → Configs (alphabetically) → Aliases → Completion

**Reload**: `dr -r` shows instructions, `source ~/.drrc` actually reloads

---

## Script Execution Flow

```
dr script-name args...
    ↓
Primary Router (case $1):
├── -l/-L     → list_scripts()
├── -r        → reload instructions
├── -a        → aliases namespace
├── -c        → config namespace
├── -col      → collections namespace
└── *         → run_script()
```

**Script discovery** (`find_script_file()`):

1. Explicit path: If contains `/`, check `scripts/path.sh` directly
2. Basename fallback: Search entire `scripts/` recursively

---

## Helper System

**`loadHelpers` function** - 5-level pattern matching:

1. Absolute path: `/path/to/helper.sh`
2. Exact path with .sh: `gcp/workstation.sh`
3. Path + auto extension: `gcp/workstation` → `.sh` added
4. Collection-prefixed: `dotrun-anc/gcp/workstation`
5. Filename only: `workstation` (searches all)

**Usage in scripts**:

```bash
#!/usr/bin/env bash
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/colors   # Load specific
loadHelpers workstation     # Search by name
loadHelpers @my-collection  # Load all from collection
```

**Safety**: Circular dependency protection (max depth: 10), path canonicalization

---

## Collections

**Strategy**: Copy-based import (users own imported files)

**Hash tracking**: SHA256 (8-char) detects local modifications

**Conflict resolution**:

- Unmodified: Update, Diff, Skip
- Modified: Keep, Overwrite, Diff, Merge, Backup

**Collection structure**:

```yaml
# dotrun.collection.yml
name: "team-scripts"
version: "1.0.0"
description: "Team automation"
author: "DevOps"
repository: "https://github.com/team/scripts.git"
```

---

## Documentation System

Scripts use `### DOC` markers:

```bash
#!/usr/bin/env bash
### DOC
# One-line description (shown in dr -L)
### DOC
# Extended help (shown in dr help <name>)
### DOC
```

- `dr -L`: Content between 1st and 2nd markers
- `dr help`: Content between 2nd and 3rd markers
