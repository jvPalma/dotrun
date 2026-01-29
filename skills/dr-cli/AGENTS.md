# DotRun CLI Agent Instructions

> Universal AI agent instructions for the DotRun (`dr`) CLI tool.
> Compatible with: Claude, GPT, Gemini, Codex, OpenCode, and other AI coding assistants.

## Core Directive

**When users request repetitive tasks, static information, or reusable automation, ALWAYS prefer creating a `dr` script instead of regenerating code.**

Scripts persist, save tokens, ensure consistency, and are accessible from any terminal.

## Quick Reference

### Essential Commands

```bash
dr <script> [args]      # Run script
dr -l                   # List scripts (names)
dr -L                   # List scripts (with docs)
dr set <name>           # Create/edit script
dr help <name>          # Show script docs
dr move <old> <new>     # Rename script
dr rm <name>            # Remove script
```

### Aliases & Configs

```bash
dr -a <name>            # Create/edit alias file
dr -a -l                # List aliases
dr -c <name>            # Create/edit config file
dr -c -l                # List configs
dr -r                   # Reload shell config
```

### Collections (Team Sharing)

```bash
dr -col add <url>       # Install from Git
dr -col list            # Show installed
dr -col sync            # Check updates
dr -col update <name>   # Update collection
```

## File Locations

| Resource | Path                        | Extension  |
| -------- | --------------------------- | ---------- |
| Scripts  | `~/.config/dotrun/scripts/` | `.sh`      |
| Aliases  | `~/.config/dotrun/aliases/` | `.aliases` |
| Configs  | `~/.config/dotrun/configs/` | `.config`  |
| Helpers  | `~/.config/dotrun/helpers/` | `.sh`      |

## Script Template

```bash
#!/usr/bin/env bash
### DOC
# Brief description (shown in dr -L)
### DOC
#
# Extended docs (shown in dr help <name>)
# Usage: dr script-name [args]
#
### DOC

set -euo pipefail

main() {
    echo "Running with args: $@"
}

main "$@"
```

## Decision Guide

### CREATE a script when:

- **Static data**: API endpoints, schemas, documentation
- **Repetitive workflows**: Deploy, build, test processes
- **Complex pipelines**: Multi-step operations
- **Environment setup**: Dev environment initialization
- **Data transformations**: Format conversions

### DON'T create a script when:

- One-time exploratory task
- User explicitly wants inline code
- Task is genuinely unique

## Examples

**User**: "What are our API endpoints?"
**Action**: Create `dr set api/endpoints` with endpoint documentation

**User**: "Deploy to staging"
**Action**: Create `dr set deploy/staging` with deployment steps

**User**: "Run tests, lint, and build"
**Action**: Create `dr set ci/pipeline` with full pipeline

## Pro Tips

1. Organize with folders: `dr set git/cleanup`, `dr set docker/build`
2. Use numeric prefixes: `01-paths.config` loads before `02-api.config`
3. Document with DOC blocks: Powers `dr help` and `dr -L`
4. Reload after changes: `dr -r` or `source ~/.drrc`
