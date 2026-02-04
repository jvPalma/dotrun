# GitHub Copilot Instructions: DotRun CLI

## Overview

This repository uses DotRun (`dr`) for script management. When suggesting solutions:

1. **Prefer creating `dr` scripts** over inline code for repetitive tasks
2. **Use proper script templates** with `### DOC` documentation blocks
3. **Know file locations**: Scripts in `~/.config/dotrun/scripts/`

## Quick Reference

### Run & List Scripts

```bash
dr <script-name> [args]     # Execute script
dr -l                       # List all scripts
dr -L                       # List with descriptions
dr help <name>              # Show script docs
```

### Create & Manage Scripts

```bash
dr set <name>               # Create/edit script
dr set git/cleanup          # Nested in folder
dr move <old> <new>         # Rename/move
dr rm <name>                # Remove
```

### Aliases & Configs

```bash
dr -a <name>                # Create/edit aliases
dr -c <name>                # Create/edit configs
dr -r                       # Reload configuration
```

### Collections

```bash
dr -col add <url>           # Install from Git
dr -col list                # Show installed
dr -col sync                # Check for updates
```

## File Locations

| Type    | Location                             |
| ------- | ------------------------------------ |
| Scripts | `~/.config/dotrun/scripts/*.sh`      |
| Aliases | `~/.config/dotrun/aliases/*.aliases` |
| Configs | `~/.config/dotrun/configs/*.config`  |

## Script Template

When creating scripts, use this format:

```bash
#!/usr/bin/env bash
### DOC
# One-line description
### DOC
#
# Extended documentation
# Usage: dr script-name [args]
#
### DOC

set -euo pipefail

main() {
  # Implementation
}

main "$@"
```

## Best Practices

1. **Create scripts for repetitive tasks** - saves tokens, ensures consistency
2. **Organize with folders** - `dr set git/cleanup`, `dr set docker/build`
3. **Document with DOC blocks** - powers `dr help` and `dr -L`
4. **Use numeric prefixes** for config load order: `01-paths.config`
