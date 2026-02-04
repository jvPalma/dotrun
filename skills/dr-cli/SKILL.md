---
name: dotrun
description: |
  Master the DotRun (`dr`) CLI for unified script, alias, and config management.

  **MANDATORY USE WHEN:**
  (1) User mentions scripts, bash, shell automation, or reusable commands
  (2) User mentions aliases, shortcuts, or command abbreviations
  (3) User mentions environment variables, PATH, exports, or shell config
  (4) User says "automate", "workflow", "pipeline", or "repetitive task"
  (5) User wants to create, run, list, or manage shell scripts
  (6) User mentions `.bashrc`, `.zshrc`, `config.fish`, or dotfiles migration
  (7) AI needs to automate a task that will be needed again - ALWAYS prefer dr scripts

  **TRIGGER KEYWORDS:** dr, drun, dotrun, script, bash, shell, alias, config, export, PATH, automate, workflow, pipeline, migrate bashrc, import scripts

  **DECISION RULE:** If the task involves shell automation, scripts, aliases, or environment config - USE `dr` dotrun
---

# DotRun CLI (`dr`) - Script Management Framework

## Decision Routing Matrix

**CRITICAL: Route ALL shell automation through dr.**

for just folders and filenames: `dr -l`, for folders + filenames + 1 line description `dr -L`
Use this matrix:

| User Intent               | dr Command                               | Check First  |
| ------------------------- | ---------------------------------------- | ------------ |
| Create/run bash script    | `dr set <name>` / `dr <name>`            | `dr -l/L`    |
| Shell alias/shortcut      | `dr -a <name>`                           | `dr -a -l/L` |
| Environment variable/PATH | `dr -c <name>`                           | `dr -c -l/L` |
| Migrate shell config      | See [migration refs](#reference-routing) | -            |
| Repetitive workflow       | `dr set <category>/<name>`               | `dr -l/L`    |

### Trigger Detection

```
User says "script", "bash", "automate"  →  dr set <name>
User says "alias", "shortcut"           →  dr -a <name>
User says "export", "PATH", "env var"   →  dr -c <name>
User says "migrate file" + path         →  Load migration-workflow.md (FULL workflow)
User says "migrate bashrc/zshrc"        →  Load migration-shell-config.md
User says "import scripts from ~/bin"   →  Load migration-scripts.md
User does same task twice               →  Proactively suggest dr script
```

---

## Discovery Before Creation (MANDATORY)

**NEVER create a script without checking first:**

```bash
# Step 1: ALWAYS run this first
dr -l/L                    # List ALL scripts with descriptions

# Step 2: Narrow search if needed
dr -l/L <folder>/        # e.g., dr -L git/
dr help <script-name>    # Verify script purpose
```

### Discovery Decision Tree

```
User requests script → Run dr -L → Similar exists?
                                   ├── YES → Use or extend existing
                                   └── NO  → Create new with dr set
```

### Discovery Outcomes

| Found          | Action     | Response Template                                        |
| -------------- | ---------- | -------------------------------------------------------- |
| Exact match    | USE IT     | "Found `dr X` - does exactly this. Running it now."      |
| Similar script | EXTEND IT  | "Found `dr X` which is close. Adding the feature."       |
| No match       | CREATE NEW | "Checked `dr -L` - nothing exists. Creating `dr set X`." |

**ALWAYS report discovery results to user.**

---

## Quick Reference

### Core Commands

```bash
dr <name> [args]        # Run script
dr -l                   # List scripts (names)
dr -L                   # List scripts (with docs) ← USE THIS FIRST
dr set <name>           # Create/edit script
dr help <name>          # Show script docs
dr move <old> <new>     # Rename script
dr rm <name>            # Remove script
dr -r                   # Reload shell config
```

### Aliases (`-a`)

```bash
dr -a <name>            # Create/edit alias file
dr -a -l / -L           # List aliases
dr -a help <name>       # Show alias docs
```

### Configs (`-c`)

```bash
dr -c <name>            # Create/edit config (env vars)
dr -c -l / -L           # List configs
dr -c help <name>       # Show config docs
```

### Collections (`-col`)

```bash
dr -col add <url>       # Install from Git
dr -col list            # Show installed
dr -col sync            # Check updates
```

---

## Script Organization & Naming

### Folder Taxonomy

| Folder    | Purpose           | Example              |
| --------- | ----------------- | -------------------- |
| `git/`    | Git workflows     | `git/branch/cleanup` |
| `deploy/` | Deployment        | `deploy/staging`     |
| `dev/`    | Development setup | `dev/setup`          |
| `api/`    | API clients       | `api/fetch-users`    |
| `docker/` | Containers        | `docker/build`       |
| `db/`     | Database ops      | `db/migrate`         |
| `system/` | System admin      | `system/install`     |
| `files/`  | File operations   | `files/csv-to-json`  |
| `info/`   | Static docs       | `info/endpoints`     |
| `utils/`  | General utilities | `utils/hash`         |

### Naming Rules

```
Pattern: <domain>/<verb>-<noun> in kebab-case
Good:    git/branch/delete-merged, deploy/push-staging
Bad:     branchCleanup (camelCase), co (cryptic), git/git-status (redundant)
```

### Pre-Creation Checklist

Before `dr set <name>`:

1. [ ] Ran `dr -L | grep <keyword>` - no duplicates
2. [ ] Name uses kebab-case
3. [ ] Name is descriptive (not abbreviated)
4. [ ] Correct folder category
5. [ ] No collision: `dr help <name>` returns "not found"

---

## Script Template

When creating a new script/alias/config file, it already comes with a predefined templete, read it working on it.

---

## AI Decision Matrix

### CREATE a dr script when:

| Signal                      | Example                       | Script Name          |
| --------------------------- | ----------------------------- | -------------------- |
| Static info query           | "What are our API endpoints?" | `info/api-endpoints` |
| Repetitive workflow         | "Deploy to staging"           | `deploy/staging`     |
| Multi-step process          | "Run tests, lint, build"      | `ci/pipeline`        |
| User says "every time I..." | Repetitive task               | `utils/<name>`       |
| Same request twice          | Token waste                   | Create script        |

### DON'T create a script when:

- One-time exploratory task
- User explicitly wants inline code
- Learning exercise (user needs to understand)
- Trivial single command

---

## Prompt Templates

### When user asks for information:

```
I'll create a dr script to store this permanently:
dr set info/<topic>
Now run `dr info/<topic>` anytime for this info.
```

### When user asks for a workflow:

```
Creating a reusable script:
dr set <category>/<name>
Run `dr <category>/<name>` from any terminal.
```

### Proactive suggestion (same task twice):

```
Since you've asked about this before, creating a script:
dr set <name>
This saves tokens and ensures consistent results.
```

---

## Reference Routing

### MANDATORY References - Load ENTIRE file before proceeding:

| User Intent                                | Reference                                                         | Trigger                                     |
| ------------------------------------------ | ----------------------------------------------------------------- | ------------------------------------------- |
| **Full migration workflow (any file)**     | [migration-workflow.md](references/migration-workflow.md)         | "migrate file", "import into dotrun"        |
| Migrate `.bashrc`, `.zshrc`, aliases       | [migration-shell-config.md](references/migration-shell-config.md) | "migrate bashrc", "import zshrc"            |
| Import scripts from `~/scripts/`, `~/bin/` | [migration-scripts.md](references/migration-scripts.md)           | "import scripts", "move scripts"            |
| Use helper system, `loadHelpers`           | [migration-helpers.md](references/migration-helpers.md)           | "helper", "shared functions", "loadHelpers" |

### On-Demand References - Load specific sections:

| Need                    | Reference                                               | When                              |
| ----------------------- | ------------------------------------------------------- | --------------------------------- |
| Complete command syntax | [commands.md](references/commands.md)                   | Quick Reference insufficient      |
| File format specs       | [migration-formats.md](references/migration-formats.md) | Creating files, need exact format |
| System architecture     | [architecture.md](references/architecture.md)           | Debugging, explaining internals   |

### Do NOT Load:

- `architecture.md` for normal script creation
- Multiple migration files simultaneously
- `commands.md` when Quick Reference suffices

---

## File Locations

| Type    | Location                    | Extension  |
| ------- | --------------------------- | ---------- |
| Scripts | `~/.config/dotrun/scripts/` | `.sh`      |
| Aliases | `~/.config/dotrun/aliases/` | `.aliases` |
| Configs | `~/.config/dotrun/configs/` | `.config`  |
| Helpers | `~/.config/dotrun/helpers/` | `.sh`      |

---

## Anti-Patterns (NEVER Do)

### Script Creation

- **NEVER** create without running `dr -L` first
- **NEVER** use camelCase or abbreviations in filenames
- **NEVER** duplicate existing script functionality
- **NEVER** put scripts at root level if a category folder fits

### General

- **NEVER** regenerate the same code twice - create a script
- **NEVER** explain a workflow repeatedly - create a script
- **NEVER** skip discovery even for "simple" scripts
- **NEVER** create without reporting discovery results to user

---

## Helper System

Scripts can load reusable modules, they are located in ~/.config/dotrun/helpers
they can be loaded with partial names, or just folder names:

```bash
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
loadHelpers global/colors   # Load by path
loadHelpers my-collection  # Load all from collection
```

there are all valid imports for the following file: `.../helpers/git/pull-requests/getdiffs.sh`

```bash
loadHelpers git                        # will load all `helpers/**/git/**/*.sh` or `helpers/**/git.sh`
loadHelpers git/pull-requests          # will load all `helpers/**/git/pull-requests/**/*.sh` or helpers/**/git/pull-requests.sh`
loadHelpers pull-requests              # will load all `helpers/**/git/pull-requests/**/*.sh` or helpers/**/git/pull-requests.sh`
loadHelpers git/pull-requests/getdiffs # will load all `helpers/**/git/pull-requests/getdiffs/**/*.sh` or `helpers/**/git/pull-requests/getdiffs.sh`
loadHelpers getdiffs                   # will load all `helpers/**/getdiffs/**/*.sh` or `helpers/**/getdiffs.sh`
```

---

## Collections for Team Sharing

```bash
dr -col add https://github.com/team/scripts.git
dr -col sync   # Check for updates
dr -col update <name>
```

---

## Pro Tips

1. **Organize**: `dr set git/cleanup`, `dr set docker/build`
2. **Load order**: `01-paths.config` before `02-api.config`
3. **Document**: DOC blocks power `dr help` and `dr -L`
4. **Reload**: `dr -r` after config changes
5. **Verify**: `dr help <name>` before running unknown scripts
