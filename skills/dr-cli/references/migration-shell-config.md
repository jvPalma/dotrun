# Shell Config Migration

> Migrate `.bashrc`, `.zshrc`, `config.fish` to DotRun's structured system.

## Quick Workflow

```
1. DETECT  → Find shell config files
2. PARSE   → Extract aliases, exports, functions
3. REVIEW  → Interactive categorization
4. MIGRATE → Create DotRun files
5. VERIFY  → Test and cleanup
```

---

## Phase 1: Detection

| Shell | Primary Config               | Secondary                            |
| ----- | ---------------------------- | ------------------------------------ |
| Bash  | `~/.bashrc`                  | `~/.bash_profile`, `~/.bash_aliases` |
| Zsh   | `~/.zshrc`                   | `~/.zprofile`, `~/.zshenv`           |
| Fish  | `~/.config/fish/config.fish` | `conf.d/*.fish`, `functions/*.fish`  |

---

## Phase 2: Pattern Extraction

### Aliases (Bash/Zsh)

```regex
^alias\s+([a-zA-Z_][a-zA-Z0-9_-]*)=['"](.+)['"]
```

### Exports

```regex
^export\s+([A-Z_][A-Za-z0-9_]*)=["']?(.+)["']?$
```

### Fish Conversion

| Fish                    | Bash                        |
| ----------------------- | --------------------------- |
| `abbr gc 'git commit'`  | `alias gc='git commit'`     |
| `set -gx API_KEY "val"` | `export API_KEY="val"`      |
| `fish_add_path /path`   | `export PATH="/path:$PATH"` |

---

## Phase 3: Auto-Categorization

### Alias Categories

| Pattern            | DotRun File             |
| ------------------ | ----------------------- |
| `g*`, `git*`       | `05-git.aliases`        |
| `d*`, `docker*`    | `10-docker.aliases`     |
| `k*`, `kubectl*`   | `15-kubernetes.aliases` |
| `..`, `cd*`, `ls*` | `01-navigation.aliases` |
| Other              | `90-misc.aliases`       |

### Export Categories

| Pattern            | DotRun File        |
| ------------------ | ------------------ |
| `PATH`, `*_BIN`    | `01-paths.config`  |
| `*_TOKEN`, `*_KEY` | `05-api.config`    |
| `EDITOR`, `VISUAL` | `03-editor.config` |
| `AWS_*`, `GCP_*`   | `20-cloud.config`  |

---

## Phase 4: File Templates

### Alias File

```bash
#!/usr/bin/env bash
# DotRun Aliases - Git
# Migrated from: ~/.zshrc on YYYY-MM-DD

alias gs='git status -sb'
alias gc='git commit -m'
```

### Config File

```bash
#!/usr/bin/env bash
# DotRun Config - Paths
# Migrated from: ~/.zshrc on YYYY-MM-DD

export PATH="$HOME/.local/bin:$PATH"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

### Function → Script

Complex functions become scripts:

```bash
#!/usr/bin/env bash
### DOC
# mkcd - Make directory and cd into it
### DOC
# Migrated from: ~/.zshrc line 45
### DOC

set -euo pipefail
mkdir -p "$1" && cd "$1"
```

---

## Phase 5: Verification

```bash
# Syntax check
for f in ~/.config/dotrun/aliases/*.aliases; do
  bash -n "$f" || echo "Error in $f"
done

# Reload and test
source ~/.drrc
alias gs  # Should show migrated alias
```

---

## Migration Mapping

| Source           | Target           | Extension  |
| ---------------- | ---------------- | ---------- |
| alias            | `aliases/`       | `.aliases` |
| export           | `configs/`       | `.config`  |
| simple function  | Convert to alias | `.aliases` |
| complex function | `scripts/`       | `.sh`      |
| PS1/PROMPT       | Do not migrate   | -          |
| shopt/setopt     | Do not migrate   | -          |

---

## Conflict Resolution

| Scenario                   | Options                        |
| -------------------------- | ------------------------------ |
| Target exists (unmodified) | Update, Diff, Skip             |
| Target exists (modified)   | Keep, Overwrite, Merge, Backup |

Backup location: `~/.config/dotrun/.backups/YYYYMMDD-HHMMSS/`
