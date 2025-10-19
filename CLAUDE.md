<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Project Overview

DotRun is a unified script management system that transforms scattered shell scripts and command sequences into a searchable, shareable toolkit. It's written in Bash and supports Bash, Zsh, and Fish shells across Linux, macOS, and Windows (WSL).

**Core Concept**: Users create scripts in `~/.config/dotrun/scripts/` and execute them from anywhere using `dr scriptname`. Scripts can be organized in folders, documented, shared as collections, and imported from repositories.

## Architecture

### Main Components

1. **`dr`** - Main executable (Bash script)
   - Command parser and router
   - Implements all core commands (-l, add, edit, move, help, etc.)
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

### Helper Loading System

**Problem**: Collection scripts use static helper imports like `source "$DR_CONFIG/helpers/gcp/workstation.sh"`, but collections are imported into dynamically-named namespace directories like `~/.config/dotrun/helpers/01-dotrun-anc/gcp/workstation.sh`. The numeric prefix (`01-`) controls load order and can be changed by users, breaking static import paths.

**Solution**: The `loadHelpers` function provides flexible, pattern-based helper loading that works regardless of namespace prefixes.

**Core Location**: `~/.local/share/dotrun/helpers/loadHelpers.sh`

**Integration Points**:

- **Shell Integration**: `~/.drrc` exports `DR_LOAD_HELPERS` and sources the function for interactive shells
- **Script Execution**: `dr` binary exports `DR_LOAD_HELPERS` before running scripts
- **Dual-Mode Support**: Works both via `dr scriptname` and direct `bash script.sh` execution

**Architecture**:

```bash
# Collection scripts source the function at the top
#!/usr/bin/env bash
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Then use flexible patterns to load helpers
loadHelpers gcp/workstation         # Load from any collection
loadHelpers dotrun-anc/utils/common # Specify collection name
loadHelpers @dotrun-anc             # Load all helpers from collection
```

**5-Level Specificity Matching** (from most to least specific):

1. **Absolute Path**: `/full/path/to/helper.sh` - Exact file path
2. **Exact Path**: `helpers/01-dotrun-anc/gcp/workstation.sh` - Exact relative path
3. **With Extension**: `01-dotrun-anc/gcp/workstation` - Auto-adds `.sh` extension
4. **Path Search**: `gcp/workstation` or `dotrun-anc/gcp/workstation` - Searches all collections
   - Collection name normalization: `dotrun-anc` matches `*-dotrun-anc` directories
   - Searches: `*/[0-9]*-collection/path.sh`, `*/collection/path.sh`
5. **Filename Only**: `workstation` - Least specific, searches all helpers

**Pattern Examples** (all work for `~/.config/dotrun/helpers/01-dotrun-anc/gcp/workstation.sh`):

```bash
loadHelpers 01-dotrun-anc/gcp/workstation.sh # Level 2: Exact with namespace
loadHelpers 01-dotrun-anc/gcp/workstation    # Level 3: Exact without .sh
loadHelpers dotrun-anc/gcp/workstation       # Level 4: Collection normalized
loadHelpers gcp/workstation                  # Level 4: Path in any collection
loadHelpers workstation                      # Level 5: Filename only
```

**Special Features**:

**Collection Scope** - Load all helpers from a collection:

```bash
loadHelpers @dotrun-anc # Loads all .sh files from *-dotrun-anc directory
```

**List Mode** - Preview matches without loading:

```bash
loadHelpers gcp/workstation --list
# Output:
# Found 1 helper(s) matching 'gcp/workstation' (level: path):
#   /home/user/.config/dotrun/helpers/01-dotrun-anc/gcp/workstation.sh
```

**Multiple Matches** - Less specific patterns may load multiple helpers:

```bash
loadHelpers utils # Loads utils.sh from all collections that have it
# Warning: Multiple helpers matched 'utils' (level: filename)
#   - /home/user/.config/dotrun/helpers/01-dotrun-anc/utils.sh
#   - /home/user/.config/dotrun/helpers/02-myteam/utils.sh
# Loading all matches...
```

**Environment Modes**:

- `DR_HELPERS_VERBOSE=1` - Enable verbose output showing search process
- `DR_HELPERS_QUIET=1` - Suppress non-error output (only errors shown)

**Security Features**:

1. **Path Traversal Prevention**: All resolved paths validated against `$DR_CONFIG/helpers`

   ```bash
   # Security check using canonical paths
   canonical_path="$(readlink -f "$helper")"
   if [[ "$canonical_path" != "$allowed_base"* ]]; then
     echo "Error: Helper outside allowed directory: $helper" >&2
     return 1
   fi
   ```

2. **Circular Dependency Detection**: Maximum depth limit of 10

   ```bash
   declare -gri _DR_LOAD_DEPTH_MAX=10
   
   # Check before loading
   ((_DR_LOAD_DEPTH++))
   if [[ $_DR_LOAD_DEPTH -gt $_DR_LOAD_DEPTH_MAX ]]; then
     echo "Error: Maximum helper loading depth exceeded" >&2
     return 1
   fi
   ```

3. **De-duplication**: Tracks loaded helpers by canonical path to prevent re-sourcing

   ```bash
   declare -gA _DR_LOADED_HELPERS
   
   # Check if already loaded
   canonical_path="$(readlink -f "$helper")"
   if [[ -n "${_DR_LOADED_HELPERS[$canonical_path]:-}" ]]; then
     echo "Skipping (already loaded): $helper" >&2
     return 0
   fi
   
   # Mark as loaded after sourcing
   _DR_LOADED_HELPERS["$canonical_path"]=1
   ```

**Collection Author Guidelines**:

When creating collection scripts that use helpers:

```bash
#!/usr/bin/env bash
### DOC
# myscript - Example collection script with helper loading
### DOC
set -euo pipefail

# Load the loadHelpers function (works in both dr and direct execution)
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers using flexible patterns
loadHelpers gcp/workstation # Works regardless of namespace prefix
loadHelpers utils/common    # Another helper
loadHelpers @dotrun-anc     # Or load all from collection at once

main() {
  # Use functions from loaded helpers
  echo "Script using helpers..."
}

main "$@"
```

**Best Practices**:

1. **Prefer Specific Patterns**: More specific = guaranteed unique match
   - Good: `loadHelpers dotrun-anc/gcp/workstation`
   - Risky: `loadHelpers workstation` (may load from wrong collection)

2. **Use Collection Names**: Include collection name when possible
   - Good: `loadHelpers dotrun-anc/utils/common`
   - Less specific: `loadHelpers utils/common`

3. **Test with --list**: Preview matches during development

   ```bash
   loadHelpers gcp/workstation --list
   ```

4. **Load at Top**: Source loadHelpers and load dependencies before main logic
   ```bash
   [[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
   loadHelpers required/helpers
   # ... then define functions and main logic
   ```

**Troubleshooting**:

**Error: No helpers found matching 'pattern'**

- Helper doesn't exist or path is wrong
- Use `loadHelpers pattern --list` to see what matches
- Check `~/.config/dotrun/helpers/` directory structure
- Enable verbose mode: `DR_HELPERS_VERBOSE=1 loadHelpers pattern`

**Error: Maximum helper loading depth exceeded**

- Circular dependency detected (helper A loads B, B loads A)
- Review helper dependencies and break the cycle
- Depth limit is 10 (defined in `_DR_LOAD_DEPTH_MAX`)

**Warning: Multiple helpers matched**

- Pattern is too broad, matches multiple files
- Use more specific pattern (include collection name or full path)
- Or intentionally load all matches if that's desired behavior

**Error: Helper outside allowed directory**

- Security violation: helper resolved outside `$DR_CONFIG/helpers`
- Check for path traversal attempts or symlink issues
- Verify `DR_CONFIG` environment variable is set correctly

3. **Directory Structure**

   **Tool Files** (`~/.local/share/dotrun/`):

   ```
   ~/.local/share/dotrun/
   ├── dr                        # Main binary
   ├── .dr_config_loader         # Shell detection and loader
   └── shell/                    # Shell-specific files
       ├── bash/
       │   ├── aliases.sh        # Alias loader
       │   ├── configs.sh        # Config loader
       │   └── dr_completion.bash
       ├── zsh/
       │   ├── aliases.sh
       │   ├── configs.sh
       │   └── dr_completion.zsh
       └── fish/
           ├── aliases.sh
           ├── configs.sh
           └── dr_completion.fish
   ```

   **User Content** (`~/.config/dotrun/`):

   ```
   ~/.config/dotrun/
   ├── scripts/               # User scripts (*.sh)
   │   └── [category]/        # Optional folder organization
   ├── helpers/               # Helper modules
   ├── collections/           # Imported collections metadata
   ├── configs/               # Global configuration files (*.config)
   └── aliases/               # Shell aliases (*.aliases)
   ```

4. **Collections System**

   **Architecture**: Copy-based with version tracking and conflict resolution

   **Core Location**: `core/shared/dotrun/core/collections.sh` (2200+ lines)

   **Design Philosophy**:
   - **Copy-based architecture**: Resources are copied to user workspace, not symlinked
   - **Modification tracking**: SHA256 hashes detect local changes to imported files
   - **Version management**: Git tags (vX.Y.Z) track collection versions
   - **Conflict resolution**: Interactive workflow handles update conflicts intelligently
   - **Private repository support**: Both HTTPS and SSH URLs supported

   **Storage Layout**:

   ```
   ~/.config/dotrun/collections/           # Persistent git clones
   ├── <collection-name>/
   │   ├── .git/                           # Full git repository
   │   ├── dotrun.collection.yml           # Metadata file
   │   ├── scripts/                        # Collection scripts
   │   ├── aliases/                        # Collection aliases
   │   ├── helpers/                        # Collection helpers
   │   └── configs/                        # Collection configs

   ~/.local/share/dotrun/collections.conf  # Tracking file
   ├── Lines: <collection-name>|<repo-url>|<version>|<last-sync>

   ~/.config/dotrun/                       # Imported resources
   ├── scripts/                            # Copied from collections
   ├── aliases/                            # Copied from collections
   ├── helpers/                            # Copied from collections
   └── configs/                            # Copied from collections

   ~/.config/dotrun/.dr-hashes/            # SHA256 tracking
   └── <script-name>.sha256                # Original hash for modification detection
   ```

   **Key Operations**:
   1. **Collection Installation** (`dr -col add <url>`):
      - Validates GitHub URL format (HTTPS or SSH)
      - Clones repository to `~/.config/dotrun/collections/<name>/`
      - Parses `dotrun.collection.yml` metadata
      - Shows interactive browser for resource selection
      - Copies selected resources with hash tracking
      - Records in `collections.conf`

   2. **Modification Detection**:
      - Calculate SHA256 hash during import: `sha256sum "$file"`
      - Store in `.dr-hashes/<filename>.sha256`
      - On update, compare current hash vs stored hash
      - Files with matching hashes are "unmodified"
      - Files with different hashes are "locally modified"

   3. **Update Workflow** (`dr -col update <name>`):
      - Fetch latest tags from repository
      - Detect new version from git tags
      - For each resource file:
        - **Unmodified** (hash matches): Offer update/diff/skip
        - **Modified** (hash differs): Offer keep/overwrite/diff/backup
        - **New** (in collection, not imported): Offer import/view/skip
      - Update hashes after successful updates
      - Update version in `collections.conf`

   4. **Sync Check** (`dr -col sync`):
      - For each installed collection:
        - `git fetch origin --tags`
        - Compare current version vs latest tag
        - Report available updates

   **Metadata Format** (`dotrun.collection.yml`):

   Required fields:
   - `name`: Collection identifier (alphanumeric, dashes, underscores)
   - `version`: Semantic version (X.Y.Z) matching git tag
   - `description`: One-line summary
   - `author`: Creator or organization
   - `repository`: GitHub URL (HTTPS or SSH)

   Optional fields:
   - `license`: SPDX identifier (MIT, Apache-2.0, etc.)
   - `homepage`: Documentation URL
   - `dependencies`: List of required collections

   **Version Management**:
   - Git tags must match metadata version
   - Tag format: `v1.2.3` or `1.2.3` (v prefix optional)
   - Metadata format: `1.2.3` (no v prefix)
   - Semantic versioning: MAJOR.MINOR.PATCH

   **Error Handling**:
   - Comprehensive validation with actionable error messages
   - Fuzzy matching for typos (suggests similar collection names)
   - Timeout protection for git operations (30s default)
   - Permission checking with troubleshooting steps
   - Network error detection with recovery options

   **Commands**:
   - `dr -col init` - Initialize new collection (creates metadata)
   - `dr -col add <url>` - Install collection with interactive browser
   - `dr -col list` - Show installed collections with versions
   - `dr -col sync` - Check for updates across all collections
   - `dr -col update <name>` - Update with conflict resolution
   - `dr -col remove <name>` - Remove collection tracking (keeps files)
   - `dr -col` - Interactive collection browser

   **Implementation Details**:

   **Core Functions** (in `core/collections.sh`):
   - `validate_github_url()` - Validates HTTPS/SSH GitHub URLs with detailed error messages
   - `git_clone_collection()` - Clones repository with timeout protection (30s)
   - `git_fetch_collection()` - Fetches updates with comprehensive error handling
   - `parse_collection_metadata()` - Parses and validates `dotrun.collection.yml`
   - `copy_with_hash()` - Copies file and stores SHA256 hash for tracking
   - `check_file_modified()` - Compares current hash vs stored hash
   - `interactive_collection_browser()` - Displays resources with folder navigation
   - `update_collection()` - Orchestrates update workflow with conflict resolution
   - `find_similar_collection_names()` - Fuzzy matching for typo suggestions

   **Hash Tracking Implementation**:

   ```bash
   # During import (copy_with_hash function):
   1. Copy file to destination: cp "$source" "$dest"
   2. Calculate hash: sha256sum "$dest" | awk '{print $1}'
   3. Store hash: echo "$hash" >"$DR_CONFIG/.dr-hashes/$(basename "$dest").sha256"
   
   # During update (check_file_modified function):
   1. Read stored hash: stored_hash=$(cat "$hash_file")
   2. Calculate current hash: current_hash=$(sha256sum "$file" | awk '{print $1}')
   3. Compare: [[ "$stored_hash" == "$current_hash" ]]
   4. Result: true=unmodified, false=locally modified
   ```

   **Git Operations**:

   All git operations include:
   - Timeout protection (30 seconds default)
   - Comprehensive error detection (network, auth, DNS, disk space)
   - Detailed troubleshooting steps in error messages
   - Recovery options for common failures

   ```bash
   # Example: Clone with timeout and error handling
   if ! timeout 30 git clone --quiet "$url" "$temp_dir" >&2; then
     local exit_code=$?
     case $exit_code in
       124) echo "Timeout after 30 seconds" ;;
       128) echo "Authentication failed" ;;
       *) echo "General git error" ;;
     esac
     # ... detailed troubleshooting steps
   fi
   ```

   **Update Conflict Resolution**:

   ```bash
   # For each resource file:
   if file_not_in_workspace; then
     # NEW FILE: Offer import/view/skip
     show_new_file_prompt
   elif check_file_modified; then
     # MODIFIED: Offer keep/overwrite/diff/backup
     show_modified_file_prompt
   else
     # UNMODIFIED: Offer update/diff/skip
     show_unmodified_file_prompt
   fi
   ```

   **Interactive Browser**:
   - Recursively lists all files in collection directories (scripts/, aliases/, helpers/, configs/)
   - Groups by resource type with visual headers
   - Folder navigation support (scripts/git/, scripts/docker/, etc.)
   - Bulk selection: "All scripts", "All aliases", etc.
   - Preview files before import
   - Skip already-imported files with indicators

   **Collections Tracking File** (`~/.local/share/dotrun/collections.conf`):

   ```
   Format: name|repository|version|last_sync_timestamp
   Example: dotrun|https://github.com/jvPalma/dotrun.git|3.0.0|1729612800
   ```

   **Common Development Tasks**:
   - **Add new resource type**: Update `interactive_collection_browser()` to handle new directory
   - **Change hash algorithm**: Update `copy_with_hash()` and `check_file_modified()`
   - **Add validation rule**: Update `parse_collection_metadata()` with new checks
   - **Improve error messages**: Update specific operation functions with detailed troubleshooting
   - **Test collections**: Create test collection repository with proper metadata structure

### Script Resolution

Scripts are found via `find_script_file()` in dr:712-212:

1. If query contains `/`, look for exact path: `$BIN_DIR/$query.sh`
2. Otherwise search recursively for basename match
3. Validates executable permissions and checks for broken symlinks

### Documentation System

Documentation format:

**Inline docs**: Scripts use `### DOC` markers for self-documenting help text accessed via `dr help scriptname`. This provides comprehensive usage information, examples, and descriptions directly in the script files.

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
- Test core commands (list, add, edit, move, help)
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

# source "$DR_CONFIG/helpers/global/pkg.sh"

main() {
  echo "Running scriptname..."
}

main "$@"
```

### Move/Rename Logic

Complex implementation in dr:342-485:

- Validates source and destination names
- Handles directory structure creation
- Updates inline references to script name
- Cleans up empty directories after move
- Preserves executable permissions

### Shell Integration

Shell integration system:

1. `~/.drrc` - User sources this in their shell config
2. `~/.local/share/dotrun/.dr_config_loader` - Detects shell and loads shell-specific configs
3. `~/.local/share/dotrun/shell/{bash,zsh,fish}/` - Shell-specific loaders and completions
   - `aliases.sh` - Sources aliases from `~/.config/dotrun/aliases/`
   - `configs.sh` - Sources configs from `~/.config/dotrun/configs/`
   - `dr_completion.*` - Tab completion for each shell

Fish shell special handling:

- Completions installed to `~/.config/fish/completions/dr.fish`
- Doesn't source bash files, needs PATH export in config.fish

### Zsh Completion UX and Colors

Zsh completion uses a namespace-based UX optimized for script execution as the primary use case. Management commands are namespaced to avoid clutter.

**Completion Tiers**:

**Tier 1 (Primary)** - `dr <tab>`:

- **Folders** (yellow): Top-level directories with trailing `/`
- **Scripts** (cyan): Executable scripts without `.sh` extension
- **Special commands** (green): `help`, `-l`, `-L`, `-h`, `--help`
- **Hint** (dark gray): `(hint: -s/scripts, -a/aliases, -c/config, -col/collections)`

**Tier 2 (Namespaced Management)**:

- **Script management**: `dr -s <tab>` or `dr scripts <tab>` → `add`, `edit`, `move`, `rename`, `help`, `list` (green)
- **Aliases management**: `dr -a <tab>` or `dr aliases <tab>` → `init`, `add`, `list`, `edit`, `remove`, `reload` (purple)
- **Config management**: `dr -c <tab>` or `dr config <tab>` → `init`, `set`, `get`, `list`, `edit`, `unset`, `reload` (red)
- **Collections management**: `dr -col <tab>` or `dr collections <tab>` → `list`, `list:details`, `remove`

**Color Scheme**:

- **Green** (`fg=32`): Special commands at root + script management commands
- **Yellow** (`fg=33`): Folder names with trailing `/` for hierarchy navigation
- **Cyan** (`fg=36`): Script names (without `.sh` extension for cleaner display)
- **Purple** (`fg=35`): Aliases management subcommands
- **Red** (`fg=31`): Config management subcommands
- **Dark Gray** (`fg=90`): Muted hint text for namespace discovery

**Hierarchical Navigation**:

- `dr <tab>`: Shows folders (yellow), scripts (cyan), special commands (green), hint (dark gray)
- `dr folder/<tab>`: Shows subfolders and scripts in that folder (no commands, no hint)
- `dr folder/subfolder/<tab>`: Continues recursive navigation
- `dr -s add git/<tab>`: Folder navigation also works in management commands
- Folders display with trailing `/` for clarity
- Scripts display without `.sh` extension for cleaner interface

**Dual Interface**:
Both flag and subcommand styles work identically:

- `dr -s add scriptname` = `dr scripts add scriptname`
- `dr -a list` = `dr aliases list`
- `dr -c set KEY value` = `dr config set KEY value`

**Backwards Compatibility**:

- Direct commands still work: `dr add scriptname`, `dr edit scriptname`
- They just don't show in tab completion (cleaner interface, soft migration)

**Implementation**: Located in `core/shared/dotrun/shell/zsh/dr_completion.zsh` using zstyle for color configuration.

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

### Alias and Config File Naming

Alias and config files use a numbered prefix convention for controlling load order:

**Naming Format**: `NN-category.{aliases|config}`

- `NN`: Two-digit number (01, 02, 03, etc.) for load order
- `category`: Descriptive name (cd, git, docker, paths, api, etc.)
- Extension: `.aliases` for alias files, `.config` for config files

**Examples**:

```
~/.config/dotrun/aliases/
├── 01-cd.aliases          # Navigation aliases load first
├── 02-git.aliases         # Git aliases load second
└── 10-custom.aliases      # Custom aliases load later

~/.config/dotrun/configs/
├── 01-paths.config        # PATH configuration loads first
├── 02-api.config          # API keys load after PATH
└── 05-dev.config          # Dev tools config
```

**Load Order**: Files are sourced in alphanumeric order. Use numbering to ensure dependencies load first (e.g., PATH setup before tools that depend on it).

**Scripts**: User scripts use `.sh` extension and don't need numbering (they're invoked explicitly, not sourced).

### Collection Metadata Format

**Current Format**: `dotrun.collection.yml` (YAML)

See [Collections System](#collections-system) section above for complete metadata specification.

**Minimal Example**:

```yaml
name: my-collection
version: 1.0.0
description: Brief description of collection purpose
author: Your Name
repository: https://github.com/user/my-collection

# Optional fields:
license: MIT
homepage: https://docs.example.com
dependencies: []
```

**Complete Reference**: See `COLLECTION_METADATA.md` for full specification including:

- All required and optional fields with validation rules
- Versioning strategy and git tag synchronization
- Common mistakes and troubleshooting
- Complete examples for different use cases

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
- Test with and without existing `~/.drrc`

## Common Gotchas

1. **Broken Symlinks**: Script resolution validates symlinks with `readlink -e`
2. **EDITOR Not Set**: All edit commands validate EDITOR before use
3. **Circular Symlinks**: Detection in `find_script_file()` and `list_scripts()`
4. **Path Resolution**: Scripts use absolute paths, but display paths with `~` substitution for user-friendliness
5. **Fish Shell**: Doesn't source bash files - needs separate PATH and completion handling
6. **Move Operations**: Must handle script files and inline references

**Collections-Specific Gotchas**:

7. **Git Tag Version Mismatch**: Collection metadata `version` field MUST match git tag (minus optional 'v' prefix)
   - Metadata: `version: 1.2.0`
   - Git tag: `v1.2.0` or `1.2.0` (both valid)
   - Mismatch causes installation/update failures

8. **Hash File Corruption**: If `.dr-hashes/` directory or individual hash files are deleted/corrupted:
   - System cannot detect modifications
   - All files appear "modified" on update
   - Solution: Re-import collection or manually restore hashes

9. **Git Clone Timeout**: 30-second timeout on git operations can fail for large repositories
   - Solution: Manual clone to temp directory, then `dr -col add /path/to/temp`
   - Or: Increase timeout in `git_clone_collection()` function

10. **SSH Authentication**: Private repositories require SSH keys configured for GitHub
    - Test with: `ssh -T git@github.com`
    - Common issue: SSH key not added to ssh-agent
    - Solution: `ssh-add ~/.ssh/id_rsa` or configure in `~/.ssh/config`

11. **Metadata File Name**: Must be exactly `dotrun.collection.yml` or `dotrun.collection.yaml`
    - NOT: `.dr-collection.yml` (old format)
    - NOT: `collection.yml` or other variants
    - Must be in repository root directory

12. **Collection Name Conflicts**: Collection names must be unique across installed collections
    - Collection name comes from metadata `name` field, not repository name
    - Installing two collections with same name will conflict

13. **Modified File Updates**: When updating modified files, choose carefully:
    - **Keep**: Preserves local changes, skips collection update
    - **Overwrite**: Loses local changes permanently (unless backed up)
    - **Backup**: Creates `.backup` copy before overwriting
    - No automatic merge - manual merge required if keeping custom changes

14. **Collections Directory Corruption**: If `~/.config/dotrun/collections/<name>/.git` is deleted:
    - Collection cannot be updated (not a git repository)
    - Solution: Remove and re-add collection: `dr -col remove <name>` then `dr -col add <url>`

15. **Tracking File Format**: `collections.conf` uses pipe-delimited format
    - Manually editing requires exact format: `name|url|version|timestamp`
    - Malformed lines cause parsing errors
    - Better to use commands rather than manual editing


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
# Read from VERSION file at runtime
DRUN_VERSION="$(cat "$SCRIPT_DIR/VERSION")"

# Fallback if VERSION file not found
DRUN_VERSION="3.0.0"
```

Also referenced in README badge. Update VERSION file, README badge, and git tag for releases:

```bash
# 1. Update VERSION file
echo "3.0.0" >VERSION

# 2. Update README badge
# Change: version-2.0.0 → version-3.0.0

# 3. Commit and tag
git add VERSION README.md
git commit -m "Release v3.0.0"
git tag v3.0.0
git push origin main --tags
```
