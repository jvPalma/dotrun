# DotRun Architecture Overview

## System Purpose

DotRun is a **script lifecycle management system** that transforms the typical developer workflow from:

```
Search for script → Find it → Remember path → Execute from specific location
```

To:

```
dr scriptname [args]  # From anywhere, instantly
```

## Core Design Philosophy

### 1. Unified Access Point

- Single command (`dr`) for all operations
- No need to remember paths or navigate directories
- Tab completion across all scripts

### 2. Self-Documenting

- Scripts carry their own documentation
- `dr help <script>` shows quick reference
- `dr docs <script>` shows comprehensive guide

### 3. Shareable by Design

- Collections system for team sharing
- Git-based distribution
- Personal vs shared script separation

### 4. Shell-Agnostic

- Works identically in Bash, Zsh, Fish
- Shell-specific optimizations where needed
- Single codebase, multiple shell support

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Shell                           │
│  (bash/zsh/fish with dr completion loaded)                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    dr (Main Script)                        │
│  • Command Parser                                            │
│  • Router (case statement)                                   │
│  • Core Functions (list, add, edit, move, help, docs)       │
└────────┬─────────────┬─────────────┬───────────┬────────────┘
         │             │             │           │
         ▼             ▼             ▼           ▼
  ┌──────────┐  ┌───────────┐  ┌─────────┐  ┌──────────┐
  │Collections│  │  Aliases  │  │ Config  │  │   Lint   │
  │  Helper  │  │  Helper   │  │ Helper  │  │  Helper  │
  └────┬─────┘  └─────┬─────┘  └────┬────┘  └─────┬────┘
       │              │              │             │
       ▼              ▼              ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Filesystem Layer                          │
│  ~/.config/dotrun/                                           │
│  ├── bin/           (User scripts + imported collections)    │
│  ├── docs/          (Markdown documentation)                 │
│  ├── helpers/       (Helper modules)                         │
│  ├── collections/   (Collection metadata)                    │
│  ├── config/shell/  (Shell-specific configs)                │
│  └── aliases/shell/ (Shell-specific aliases)                │
└─────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. Main dr Script (~1022 lines)

**Location**: `dr`

**Responsibilities**:

- Parse command-line arguments
- Route commands to appropriate handlers
- Implement core functionality (list, add, edit, move, help, docs)
- Source helper modules dynamically
- Manage script lifecycle

**Key Functions**:

```bash
list_scripts()         # Display scripts in tree format
create_script_skeleton() # Generate new script template
find_script_file()     # Locate script by name/path
add_script()           # Create and open new script
edit_script()          # Edit existing script
edit_docs()            # Edit markdown documentation
move_script()          # Move/rename scripts
run_script()           # Execute user script
show_help()            # Display inline documentation
show_docs()            # Display markdown documentation
```

**Command Router** (lines 501-1022):

```bash
case "${1:-}" in
  -l | -L)        list_scripts "$show_docs" "$scope" ;;
  add)            add_script "$2" ;;
  edit)           edit_script "$2" ;;
  move | rename)  move_script "$2" "$3" ;;
  help)           show_help "$2" ;;
  docs)           show_docs "$2" ;;
  # ... etc
  *)              run_script "$@" ;;  # Default: run as script
esac
```

### 2. Helper System

**Location**: `helpers/`

**Design Pattern**: Dynamic sourcing

```bash
LINT_HELPER="$DR_CONFIG/helpers/lint.sh"
[[ -f "$LINT_HELPER" ]] && source "$LINT_HELPER"
```

**Modules**:

#### collections.sh (~613 lines)

- Import/export script collections
- Git repository integration
- Collection validation
- YADM dotfiles integration

Key exports:

- `import_collection()`
- `export_collection()`
- `preview_collection()`
- `import_single_script()`
- `list_collections()`
- `remove_collection()`
- `yadm_init()`

#### aliases.sh (~400+ lines)

- Shell alias management
- Category-based organization
- Shell-specific alias files

Key exports:

- `aliases_init()`
- `aliases_add()`
- `aliases_list()`
- `aliases_edit()`
- `aliases_remove()`
- `aliases_reload()`

#### config.sh (~600+ lines)

- Global configuration variables
- Secure value storage
- Category-based organization
- Shell-specific config files

Key exports:

- `config_init()`
- `config_set()`
- `config_get()`
- `config_list()`
- `config_edit()`
- `config_unset()`
- `config_reload()`

#### pkg.sh (~50 lines)

- Package manager detection
- Command validation
- Installation hints

Key exports:

- `detect_lang()`
- `pkg_install_hint()`
- `validatePkg()`

#### git.sh (~50 lines)

- Git utility functions
- Repository operations

#### lint.sh (~30 lines)

- ShellCheck integration
- Automatic linting after edit

Key exports:

- `run_shell_lint()`

### 3. Filesystem Structure

**Root**: `~/.config/dotrun/`

```
~/.config/dotrun/
├── bin/                      # Executable scripts
│   ├── *.sh                 # Top-level scripts
│   ├── category1/           # Organized by category
│   │   └── *.sh
│   └── collection-name/     # Imported collections
│       └── *.sh
│
├── docs/                     # Markdown documentation
│   ├── *.md                 # Matches bin/ structure
│   ├── category1/
│   │   └── *.md
│   └── collection-name/
│       └── *.md
│
├── helpers/                  # Helper modules
│   ├── collections.sh
│   ├── aliases.sh
│   ├── config.sh
│   ├── pkg.sh
│   ├── git.sh
│   └── lint.sh
│
├── collections/              # Collection metadata
│   └── collection-name/
│       ├── .dr-collection.yml
│       ├── bin/
│       └── docs/
│
├── config/                   # Configuration system
│   └── shell/
│       ├── bash_config
│       ├── zsh_config
│       └── fish_config
│
├── aliases/                  # Alias system
│   └── shell/
│       ├── bash_aliases
│       ├── zsh_aliases
│       └── fish_aliases
│
├── .DR_CONFIG_loader      # Shell integration loader
├── drun_completion.bash     # Bash completion
├── drun_completion.zsh      # Zsh completion
└── drun_completion.fish     # Fish completion
```

### 4. Shell Integration System

**Three-tier integration**:

1. **User Shell Config** (`~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`)

   ```bash
   source ~/.drunrc
   ```

2. **DotRun Config Loader** (`~/.drunrc`)

   ```bash
   export DR_CONFIG="$HOME/.config/dotrun"
   source "$DR_CONFIG/.DR_CONFIG_loader"
   ```

3. **Dynamic Loader** (`~/.config/dotrun/.DR_CONFIG_loader`)
   - Detects current shell
   - Loads shell-specific completion
   - Sources shell-specific config
   - Sources shell-specific aliases
   - Adds dr to PATH

**Fish Special Handling**:

- Doesn't source bash files
- Completion installed to `~/.config/fish/completions/dr.fish`
- Needs explicit PATH export in config.fish

## Data Flow

### Script Execution Flow

```
User types: dr scriptname arg1 arg2
           ↓
    Shell interprets command
           ↓
    Executes: ~/.local/bin/dr scriptname arg1 arg2
           ↓
    dr main script starts
           ↓
    Parse arguments: scriptname arg1 arg2
           ↓
    Case statement router: No match for known commands
           ↓
    Default case: run_script "scriptname" "arg1" "arg2"
           ↓
    find_script_file("scriptname")
      • Check exact path: $BIN_DIR/scriptname.sh
      • Check recursive: find $BIN_DIR -name "scriptname.sh"
      • Validate: executable, not broken symlink
           ↓
    Execute: /path/to/scriptname.sh arg1 arg2
           ↓
    Script runs with arguments
```

### Collection Import Flow

```
User types: dr import https://github.com/user/collection.git team
           ↓
    dr routes to: import_collection "$2" "$3"
           ↓
    collections.sh: import_collection()
           ↓
    1. Create temp directory
    2. Clone repository
    3. Validate structure (.dr-collection.yml, bin/, docs/)
    4. Parse collection name from metadata or use provided name
    5. Check if collection exists (prompt for overwrite)
    6. Copy collection to $COLLECTIONS_DIR/team/
    7. Install scripts to $BIN_DIR/team/ with symlinks
    8. Copy docs to $DOC_DIR/team/
    9. Display installed scripts
           ↓
    User can now run: dr team/scriptname
```

### Documentation Display Flow

```
User types: dr docs scriptname
           ↓
    show_docs() called
           ↓
    1. find_script_file("scriptname") → get script path
    2. Convert script path to doc path:
       bin/category/script.sh → docs/category/script.md
    3. Check if doc file exists
       YES → Display with glow (if available) or cat
       NO → Fall back to show_help() (inline docs)
           ↓
    Display to user
```

## Extension Points

### Adding New Commands

Add to case statement in dr:501-1022:

```bash
case "${1:-}" in
  # ... existing commands
  newcommand)
    [[ -z "${2:-}" ]] && {
      echo "Usage: dr newcommand <arg>"
      exit 1
    }
    new_command_function "$2"
    ;;
esac
```

### Adding New Helpers

1. Create `helpers/newhelper.sh`
2. Add sourcing to dr:
   ```bash
   NEW_HELPER="$DR_CONFIG/helpers/newhelper.sh"
   [[ -f "$NEW_HELPER" ]] && source "$NEW_HELPER"
   ```
3. Implement functions
4. Export functions for use in main script

### Extending Collections

Modify `.dr-collection.yml` format:

- Add new metadata fields
- Update `parse_collection_metadata()`
- Update `validate_collection()`
- Update import/export logic

## Security Boundaries

### Input Validation

All user input passes through validation:

```bash
validate_script_name() {
  [[ "$name" =~ [^a-zA-Z0-9_/-] ]] && return 1
}
```

### File Operations

All file operations:

- Check permissions before writing
- Validate paths are within expected directories
- Check for symlink attacks
- Validate executability

### Command Execution

Script execution:

- Scripts must be in `$BIN_DIR` tree
- Must have executable permission
- Must not be broken symlinks
- Validated before execution

## Performance Considerations

### Script Lookup

Two-phase lookup:

1. **Fast path**: Direct path match O(1)
2. **Slow path**: Recursive find O(n) where n = number of scripts

**Optimization**: Use folder organization to reduce search space

### Collection Import

**Bottleneck**: Git clone operation
**Optimization**: `--depth 1` for shallow clone

### Shell Startup

**Impact**: Minimal (~10-20ms)

- Single source of `.drunrc`
- Dynamic loading of completions
- No heavy computation

## Error Handling Strategy

### Strict Mode

All scripts use:

```bash
set -euo pipefail
```

- `-e`: Exit on error
- `-u`: Error on undefined variable
- `-o pipefail`: Catch pipe failures

### Validation Points

1. **Input validation**: Before processing
2. **Prerequisite checks**: Before operations
3. **File existence**: Before reading/writing
4. **Permission checks**: Before modifying
5. **Command availability**: Before executing external tools

### Error Recovery

- Temporary files cleaned up via traps
- Operations are atomic where possible
- Clear error messages with actionable advice
- Graceful degradation (e.g., glow → cat)

## Testing Strategy

### Manual Testing

No automated test suite exists. Testing is manual:

1. **Unit testing**: Test individual commands
2. **Integration testing**: Test workflows (add → edit → run)
3. **Shell testing**: Test in bash, zsh, fish
4. **Platform testing**: Test on Linux, macOS, WSL

### Test Scenarios

See [05-testing/test-scenarios.md](../05-testing/test-scenarios.md) for comprehensive test cases.

## Future Architecture Considerations

### Potential Improvements

1. **Plugin System**: Formal plugin API for extensions
2. **Performance**: Cache script locations
3. **Validation**: Automated testing framework
4. **Distribution**: Package manager support (apt, brew, etc.)
5. **Versioning**: Script version management
6. **Dependencies**: Declare script dependencies

### Scalability Limits

- **Script Count**: Tested up to ~1000 scripts
- **Collection Size**: No practical limit
- **Shell Startup**: Minimal impact regardless of script count
- **Search Performance**: Linear with script count (could cache)

## Related Documentation

- [Control Flow](control-flow.md) - Detailed command routing
- [Data Flow](data-flow.md) - How data moves through system
- [Helper System](helper-system.md) - Helper module architecture
- [Shell Integration](shell-integration.md) - Shell-specific details
