# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DotRun is a unified script management system that transforms scattered shell scripts and command sequences into a searchable, shareable toolkit. It's written in Bash and supports Bash, Zsh, and Fish shells across Linux, macOS, and Windows (WSL).

**Core Concept**: Users create scripts in `~/.config/dotrun/bin/` and execute them from anywhere using `dr scriptname`. Scripts can be organized in folders, documented, shared as collections, and imported from repositories.

## Architecture

### Main Components

1. **`dr`** - Main executable (Bash script)
   - Command parser and router
   - Implements all core commands (-l, add, edit, move, help, docs, etc.)
   - Sources helper modules dynamically

2. **Helper System** (`helpers/` directory)
   - `collections.sh` - Import/export script collections from git repositories
   - `aliases.sh` - Manage shell aliases with categories
   - `config.sh` - Global configuration variable management
   - `pkg.sh` - Package manager helpers and validation
   - `git.sh` - Git utility functions
   - `lint.sh` - ShellCheck integration
   - `filters.sh` - Text filtering utilities
   - `constants.sh` - Shared constants

3. **Directory Structure**

   ```
   ~/.config/dotrun/
   ├── bin/                   # User scripts (*.sh)
   │   └── [category]/        # Optional folder organization
   ├── docs/                  # Markdown documentation (*.md)
   ├── helpers/               # Helper modules
   ├── collections/           # Imported collections metadata
   ├── config/shell/          # Shell-specific configs
   └── aliases/shell/         # Shell-specific aliases
   ```

4. **Collections System**
   - Collections are git repositories with structure: `bin/`, `docs/`, `.dr-collection.yml`
   - Import from git: `dr import <url> [name]`
   - Import single script: `dr import <url> --pick <script>`
   - Preview before import: `dr import <url> --preview`
   - Export to share: `dr export <name> <path> [--git]`

### Script Resolution

Scripts are found via `find_script_file()` in dr:712-212:

1. If query contains `/`, look for exact path: `$BIN_DIR/$query.sh`
2. Otherwise search recursively for basename match
3. Validates executable permissions and checks for broken symlinks

### Documentation System

Two documentation formats:

1. **Inline docs**: `### DOC` markers in script files for quick help (`dr help scriptname`)
2. **Markdown docs**: `docs/*.md` files for detailed documentation (`dr docs scriptname`)
   - Rendered with `glow` if available
   - Falls back to `cat` output

## Common Development Commands

### Running DotRun

```bash
# Test the main script
./dr --help

# Test script listing
./dr -l
./dr -L

# Add and test a new script
./dr add testscript
./dr testscript

# Test script moving/renaming
./dr move oldname newname
./dr move script folder/script
```

### Testing

No formal test suite exists. Manual testing workflow:

- Create test scripts with `dr add`
- Test core commands (list, add, edit, move, help, docs)
- Test collection import/export with example collection
- Verify shell completions in bash/zsh/fish

### Linting

ShellCheck integration via `helpers/lint.sh`:

- Automatically runs after `dr add` or `dr edit` if ShellCheck is installed
- Disable with: unset `run_shell_lint` function
- Manual check: `shellcheck dr` or `shellcheck helpers/*.sh`

### Installation Testing

```bash
# Test clean install
./install.sh

# Test force override
./install.sh --force

# Test from different directories
cd /tmp && bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

## Key Design Patterns

### Error Handling

- `set -euo pipefail` in all scripts for strict error handling
- Input validation functions (e.g., `validate_script_name()`)
- Prerequisite checks (`check_prerequisites()`)
- Writable directory validation before operations
- EDITOR validation before launching editor

### Script Creation Template

All new scripts use skeleton from `create_script_skeleton()` in dr:137-168:

```bash
#!/usr/bin/env bash
### DOC
# scriptname - describe what this script does
### DOC
set -euo pipefail

# source "$DR_CONFIG/helpers/pkg.sh"

main() {
  echo "Running scriptname..."
}

main "$@"
```

### Move/Rename Logic

Complex implementation in dr:342-485:

- Validates source and destination names
- Handles directory structure creation
- Updates both script and documentation files
- Updates inline references to script name
- Cleans up empty directories after move
- Preserves executable permissions

### Shell Integration

Three-file system:

1. `~/.drunrc` - User sources this in their shell config
2. `~/.config/dotrun/.DR_CONFIG_loader` - Loads shell-specific configs
3. `drun_completion.{bash,zsh,fish}` - Tab completion for each shell

Fish shell special handling:

- Completions installed to `~/.config/fish/completions/dr.fish`
- Doesn't source bash files, needs PATH export in config.fish

## Important Conventions

### Script Naming

- Alphanumeric, underscore, dash, and forward slash only
- No spaces in names
- Folder organization supported: `category/scriptname`
- Validation in `validate_script_name()` in dr:46-56

### DOC Token

- `### DOC` markers delimit inline documentation
- Everything between tokens is shown by `dr help`
- Extracted by awk: `/^$DOC_TOKEN/ { p = !p; next } p`

### Collection Metadata Format

`.dr-collection.yml` structure:

```yaml
name: "collection-name"
description: "Brief description"
author: "Author Name"
version: "1.0.0"
type: "dr-collection"
scripts: []
dependencies: []
environments: ["dev", "staging", "prod"]
```

### Environment Variables

- `DR_CONFIG` - Config root (default: `$HOME/.config/dotrun`)
- `EDITOR` - Editor command (default: auto-detect code or nano)
- `DRUN_VERSION` - Version string in dr script

## File Modification Notes

### When Editing `dr`

- Update `DRUN_VERSION` for releases
- Maintain case statement structure for command routing (dr:501-1022)
- Keep help text synchronized with actual commands
- Test all shell types (bash, zsh, fish) after changes

### When Editing Helpers

- Keep helper modules independent and sourceable
- Validate required commands with `validatePkg` from pkg.sh
- Use `DR_CONFIG` variable for paths, not hardcoded paths
- Source dependencies at top of file

### When Editing `install.sh`

- Test on multiple platforms (Linux, macOS, WSL)
- Test clean install vs upgrade scenarios
- Test force override mode
- Verify shell detection works correctly
- Test with and without existing `~/.drunrc`

## Common Gotchas

1. **Broken Symlinks**: Script resolution validates symlinks with `readlink -e`
2. **EDITOR Not Set**: All edit commands validate EDITOR before use
3. **Circular Symlinks**: Detection in `find_script_file()` and `list_scripts()`
4. **Path Resolution**: Scripts use absolute paths, but display paths with `~` substitution for user-friendliness
5. **Fish Shell**: Doesn't source bash files - needs separate PATH and completion handling
6. **Collection Imports**: Always validate collection structure before importing
7. **Move Operations**: Must handle both script files AND documentation files, plus inline references

## Examples Collection

`examples/` directory contains:

- Sample scripts demonstrating features
- `.dr-collection.yml` metadata
- Ready-to-import collection for testing
- AI tool examples (commit messages, PR descriptions)
- React development workflows
- Git workflow automation

To test: `./dr import ./examples test-collection`

## Code Style

- Bash with strict mode: `set -euo pipefail`
- shellcheck compliant (some disables for sourcing, SC2155, SC2016)
- Functions before usage
- Color codes via escape sequences
- Heredocs for multi-line content
- Comment blocks with box drawing characters for sections

## Version Management

Version in `dr` script:

```bash
DRUN_VERSION="1.0.1"
```

Also referenced in README badge. Update both for releases.
