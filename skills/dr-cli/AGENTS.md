# DotRun CLI Agent Instructions

> Universal AI agent instructions for the DotRun (`dr`) CLI tool.
> Compatible with: Claude, GPT, Gemini, Codex, OpenCode, and other AI coding assistants.

## Core Directive

**Route ALL shell automation through `dr`.** When users request scripts, aliases, configs, or repetitive tasks, USE DR.

**MANDATORY: Run `dr -L` BEFORE creating any script.** Check if one exists first.

## Decision Routing

| User Says                    | Command            | Check First |
| ---------------------------- | ------------------ | ----------- |
| "script", "bash", "automate" | `dr set <name>`    | `dr -L`     |
| "alias", "shortcut"          | `dr -a <name>`     | `dr -a -L`  |
| "export", "PATH", "env var"  | `dr -c <name>`     | `dr -c -L`  |
| "migrate", "import bashrc"   | Load migration ref | -           |

## Discovery Before Creation

```bash
dr -L                   # List ALL scripts with descriptions - ALWAYS FIRST
dr -L <folder>/         # Narrow to domain (git/, deploy/, etc.)
dr help <name>          # Verify script purpose
```

**Discovery outcomes:**

- **Found exact match** → Use it: "Found `dr X` - running it now."
- **Found similar** → Extend it: "Found `dr X` - adding the feature."
- **No match** → Create new: "Checked `dr -L` - creating `dr set X`."

## Migration Workflow

When user says "migrate", "import", "convert" followed by a file path:

```
MANDATORY WORKFLOW:
1. Verify → 2. Backup → 3. Analyze → 4. Plan → 5. Approve → 6. Execute → 7. Test → 8. Cleanup
```

**Trigger phrases:**

- "migrate ~/.bashrc"
- "import my bash_profile"
- "convert .zshrc to dotrun"

**NEVER:**

- Delete original without backup
- Execute without user approval
- Skip the verification step

**Reference:** See [migration-workflow.md](references/migration-workflow.md)

## Quick Reference

```bash
dr <name> [args]        # Run script
dr -L                   # List with descriptions ← USE THIS FIRST
dr set <name>           # Create/edit script
dr help <name>          # Show script docs
dr move <old> <new>     # Rename script
dr rm <name>            # Remove script
dr -a <name>            # Create/edit alias file
dr -c <name>            # Create/edit config (env vars)
dr -r                   # Reload shell config
```

## Script Naming

```
Pattern: <domain>/<verb>-<noun> in kebab-case
Folders: git/, deploy/, dev/, api/, docker/, db/, system/, files/, info/, utils/

Good: git/branch/delete-merged, deploy/push-staging
Bad:  branchCleanup (camelCase), co (cryptic)
```

## File Locations

| Type    | Location                    | Extension  |
| ------- | --------------------------- | ---------- |
| Scripts | `~/.config/dotrun/scripts/` | `.sh`      |
| Aliases | `~/.config/dotrun/aliases/` | `.aliases` |
| Configs | `~/.config/dotrun/configs/` | `.config`  |

## Script Template

```bash
#!/usr/bin/env bash
### DOC
# Brief description (shown in dr -L)
### DOC
# Extended docs (shown in dr help <name>)
### DOC

set -euo pipefail

main() {
  echo "Running: $@"
}

main "$@"
```

## NEVER Do

- **NEVER** create without running `dr -L` first
- **NEVER** regenerate same code twice - create a script
- **NEVER** use camelCase or abbreviations in filenames
- **NEVER** skip reporting discovery results to user
