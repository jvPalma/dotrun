# dr Main Script API Reference

**File**: `dr` (1022 lines)
**Language**: Bash
**Version**: 1.0.1

## Global Variables

### Configuration Variables

```bash
DRUN_VERSION="1.0.1"
# Current version of DotRun

DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
# Root configuration directory
# Can be overridden via environment variable

BIN_DIR="$DR_CONFIG/bin"
# Directory containing all executable scripts

DOC_DIR="$DR_CONFIG/docs"
# Directory containing markdown documentation

DOC_TOKEN="### DOC"
# Marker for inline documentation blocks

EDITOR="${EDITOR:-$_default_editor}"
# Editor command (auto-detected: code or nano)
```

### Helper Paths

```bash
LINT_HELPER="$DR_CONFIG/helpers/lint.sh"
ALIASES_HELPER="$DR_CONFIG/helpers/aliases.sh"
CONFIG_HELPER="$DR_CONFIG/helpers/config.sh"
```

### Color Constants

```bash
color_folder()  # Function returning color codes for folder levels
color_script="\033[1;92m"  # Bright Green
color_doc="\033[0;37m"     # Gray
color_reset="\033[0m"      # Reset
```

---

## Core Functions

### validate_script_name()

**Location**: Lines 46-56
**Purpose**: Validate script names against allowed character set

```bash
validate_script_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Error: Script name cannot be empty" >&2
    return 1
  fi
  if [[ "$name" =~ [^a-zA-Z0-9_/-] ]]; then
    echo "Error: Script name contains invalid characters..." >&2
    return 1
  fi
}
```

**Parameters**:

- `$1` (string): Script name to validate

**Returns**:

- `0`: Name is valid
- `1`: Name is invalid (empty or contains invalid characters)

**Valid Characters**: `a-z`, `A-Z`, `0-9`, `_`, `-`, `/`

**Examples**:

```bash
validate_script_name "my-script"      # ✓ Valid
validate_script_name "folder/script"  # ✓ Valid
validate_script_name "my script"      # ✗ Invalid (space)
validate_script_name "script@home"    # ✗ Invalid (@)
```

---

### check_prerequisites()

**Location**: Lines 59-68
**Purpose**: Verify required directories exist and are writable

```bash
check_prerequisites() {
  if [[ ! -d "$BIN_DIR" ]] && ! mkdir -p "$BIN_DIR" 2>/dev/null; then
    echo "Error: Cannot create or access BIN_DIR: $BIN_DIR" >&2
    exit 1
  fi
  if [[ ! -d "$DOC_DIR" ]] && ! mkdir -p "$DOC_DIR" 2>/dev/null; then
    echo "Error: Cannot create or access DOC_DIR: $DOC_DIR" >&2
    exit 1
  fi
}
```

**Parameters**: None

**Side Effects**:

- Creates `$BIN_DIR` if it doesn't exist
- Creates `$DOC_DIR` if it doesn't exist
- Exits with status 1 on failure

**Called By**:

- `add_script()`
- `import` command handler
- `export` command handler
- `collections` command handler

---

### list_scripts()

**Location**: Lines 85-135
**Purpose**: Display scripts in tree format with optional documentation

```bash
list_scripts() {
  local show_docs="$1"  # 0 = names only, 1 = include docs
  local scope="$2"      # optional sub-folder (e.g. "code/")
  # ...
}
```

**Parameters**:

- `$1` (int): `0` = names only, `1` = include inline documentation
- `$2` (string, optional): Scope to specific folder (e.g., "category/")

**Output Format**:

```
📂 folder
  scriptname
    doc line 1
    doc line 2
  📂 subfolder
    another-script
      doc line 1
```

**Algorithm**:

1. Validate scope directory exists
2. Check for broken symlinks and warn
3. Build folder tree with depth tracking
4. For each script:
   - Print folder chain (memoized to avoid duplicates)
   - Print script name with color
   - If `show_docs=1`, extract and print DOC token content

**Color Coding**:

- Folders: Yellow
- Scripts: Bright Green
- Documentation: Gray

**Error Handling**:

- Returns 1 if scope directory doesn't exist
- Warns about broken symlinks but continues

---

### create_script_skeleton()

**Location**: Lines 137-168
**Purpose**: Generate template for new script with documentation structure

```bash
create_script_skeleton() {
  local name="$1"
  # ...
}
```

**Parameters**:

- `$1` (string): Script name (can include folders: "category/script")

**Generated Files**:

1. **Script file**: `$BIN_DIR/$name.sh`

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

2. **Documentation file**: `$DOC_DIR/$name.md`

   ```markdown
   # scriptname

   Describe what this script does here.

   ## Usage

   \`\`\`bash
   $ dr scriptname [args...]
   \`\`\`
   ```

**Side Effects**:

- Creates parent directories if needed
- Makes script executable (`chmod +x`)

---

### find_script_file()

**Location**: Lines 171-212
**Purpose**: Locate script file by name or path

```bash
find_script_file() {
  local query="$1"
  # ...
}
```

**Parameters**:

- `$1` (string): Script name or path to search for

**Returns**:

- Stdout: Absolute path to script file (if found)
- Exit code: `0` = found, `1` = not found or error

**Algorithm**:

**Phase 1**: Explicit path match (if query contains `/`)

```bash
if [[ "$query" == */* ]]; then
  exact="$BIN_DIR/$query.sh"
  if [[ -f "$exact" ]]; then
    # Validate executable and not broken symlink
    echo "$exact"
    return
  fi
fi
```

**Phase 2**: Recursive basename search

```bash
base="$(basename "$query").sh"
found=$(find "$BIN_DIR" -type f -name "$base" | head -n 1)
if [[ -n "$found" ]]; then
  # Validate executable and not broken symlink
  echo "$found"
fi
```

**Validation**:

- Checks file is executable (`-x`)
- Checks symlink is not broken (`readlink -e`)
- Returns error message to stderr if invalid

**Examples**:

```bash
find_script_file "deploy"           # → $BIN_DIR/deploy.sh
find_script_file "git/cleanup"      # → $BIN_DIR/git/cleanup.sh
find_script_file "examples/hello"   # → $BIN_DIR/examples/hello.sh
```

---

### add_script()

**Location**: Lines 214-233
**Purpose**: Create new script and open in editor

```bash
add_script() {
  local name="$1"
  # ...
}
```

**Parameters**:

- `$1` (string): Script name (can include folders)

**Algorithm**:

1. Validate script name
2. Check prerequisites (directories exist)
3. Check if script already exists
   - If not: Create skeleton
4. Validate EDITOR is set and available
5. Open script in editor
6. Run ShellCheck if available

**Side Effects**:

- Creates new script file if doesn't exist
- Opens editor (blocks until closed)
- Runs linting after editor closes

**Error Conditions**:

- Invalid script name → exit 1
- EDITOR not found → exit 1
- Prerequisites check fails → exit 1

---

### edit_script()

**Location**: Lines 235-252
**Purpose**: Edit existing script in editor

```bash
edit_script() {
  local file
  file=$(find_script_file "$1")
  # ...
}
```

**Parameters**:

- `$1` (string): Script name to edit

**Algorithm**:

1. Find script file
2. Validate EDITOR is set
3. Open in editor
4. Run ShellCheck if available

**Error Conditions**:

- Script not found → exit 1
- EDITOR not found → exit 1

**User Feedback**:

- Prints: "Editing script: {name} ---- with editor: {EDITOR}"

---

### edit_docs()

**Location**: Lines 254-293
**Purpose**: Edit markdown documentation for script

```bash
edit_docs() {
  local file
  file=$(find_script_file "$1")
  # ...
}
```

**Parameters**:

- `$1` (string): Script name whose docs to edit

**Algorithm**:

1. Find script file
2. Convert script path to doc path:
   - `bin/script.sh` → `docs/script.md`
   - `bin/category/script.sh` → `docs/category/script.md`
3. Check if doc file exists
   - **Exists**: Open in editor
   - **Not exists**: Create skeleton and open

**Doc Skeleton Created**:

```markdown
# scriptname

Describe what this script does here.

## Usage

\`\`\`bash
$ dr category/scriptname [args...]
\`\`\`
```

**Path Handling**:

- Preserves folder structure from bin/ to docs/
- Creates parent directories as needed

---

### show_help()

**Location**: Lines 295-303
**Purpose**: Display inline documentation (between DOC tokens)

```bash
show_help() {
  local file
  file=$(find_script_file "$1")
  [[ -z "$file" ]] && exit 1
  awk "/^$DOC_TOKEN/ { p = !p; next } p" "$file"
}
```

**Parameters**:

- `$1` (string): Script name

**Output**: Content between `### DOC` markers

**Example**:

```bash
### DOC
# deploy - Deploy application to environment
# Usage: dr deploy [staging|production]
### DOC
```

Outputs:

```
# deploy - Deploy application to environment
# Usage: dr deploy [staging|production]
```

---

### show_docs()

**Location**: Lines 305-340
**Purpose**: Display markdown documentation with formatting

```bash
show_docs() {
  local file
  file=$(find_script_file "$1")
  # Get doc path...
  if [[ -f "$doc_file" ]]; then
    if command -v glow >/dev/null 2>&1; then
      glow "$doc_file"
    else
      cat "$doc_file"
    fi
  else
    # Fall back to inline help
    show_help "$1"
  fi
}
```

**Parameters**:

- `$1` (string): Script name

**Rendering**:

- **Preferred**: Uses `glow` for markdown rendering
- **Fallback**: Uses `cat` for plain text
- **No docs**: Falls back to `show_help()`

**User Guidance**:
If no markdown docs exist, suggests:

```
💡 Create full documentation with: dr edit:docs scriptname
```

---

### move_script()

**Location**: Lines 342-485
**Purpose**: Move or rename script and its documentation

```bash
move_script() {
  local source="$1"
  local destination="$2"
  # ...
}
```

**Parameters**:

- `$1` (string): Source script name
- `$2` (string): Destination script name

**Algorithm**:

1. **Validation**:
   - Validate both names
   - Check source exists
   - Check destination doesn't exist
   - Check not moving to itself
   - Check write permissions

2. **Path Construction**:

   ```bash
   source_file="$BIN_DIR/source.sh"
   dest_file="$BIN_DIR/destination.sh"
   source_doc="$DOC_DIR/source.md"
   dest_doc="$DOC_DIR/destination.md"
   ```

3. **Move Operations**:
   - Move script file
   - Move documentation file (if exists)
   - Update documentation content (name references)
   - Update inline documentation in script

4. **Cleanup**:
   - Remove empty source directories (cascading to parents)
   - Both bin/ and docs/ trees

5. **Content Updates**:
   - Documentation title: `# oldname` → `# newname`
   - Usage examples: `dr oldname` → `dr newname`
   - Script inline docs: Same replacements

**Examples**:

```bash
move_script "oldname" "newname"              # Simple rename
move_script "script" "category/script"       # Move to folder
move_script "cat1/script" "cat2/script"      # Move between folders
move_script "oldname" "folder/newname"       # Rename and move
```

**Edge Cases Handled**:

- Source/destination same → Error
- Destination exists → Error
- No write permission → Error
- Missing documentation → Warning, script still moved
- Empty directories → Cleaned up recursively

---

### run_script()

**Location**: Lines 487-498
**Purpose**: Execute user script with arguments

```bash
run_script() {
  local name="$1"
  shift
  local file
  file=$(find_script_file "$name")
  [[ -z "$file" ]] && exit 1
  "$file" "$@"
}
```

**Parameters**:

- `$1` (string): Script name
- `$@` (rest): Arguments to pass to script

**Algorithm**:

1. Extract script name
2. Shift arguments
3. Find script file
4. Execute with remaining arguments

**Error Handling**:

- Script not found → exit 1 with helpful message

---

## Command Router

**Location**: Lines 501-1022
**Purpose**: Parse and route commands to appropriate handlers

### Command Structure

```bash
case "${1:-}" in
  pattern)
    # validation
    # execution
    ;;
esac
```

### Supported Commands

#### Listing Commands

```bash
-l | -L)
  show_docs=0
  [[ "$1" == "-L" ]] && show_docs=1
  scope="${2:-}"
  list_scripts "$show_docs" "$scope"
  ;;
```

**Usage**:

- `dr -l` - List names only
- `dr -L` - List with docs
- `dr -l folder/` - List names in folder
- `dr -L folder/` - List with docs in folder

---

#### Script Management

```bash
add)
  [[ -z "${2:-}" ]] && { echo "Usage: dr add <name>"; exit 1; }
  add_script "$2"
  ;;

edit)
  [[ -z "${2:-}" ]] && { echo "Usage: dr edit <name>"; exit 1; }
  edit_script "$2"
  ;;

edit:docs)
  [[ -z "${2:-}" ]] && { echo "Usage: dr edit:docs <name>"; exit 1; }
  edit_docs "$2"
  ;;

move | rename | mv)
  [[ -z "${2:-}" || -z "${3:-}" ]] && {
    echo "Usage: dr move <source> <destination>"
    exit 1
  }
  move_script "$2" "$3"
  ;;
```

---

#### Documentation Commands

```bash
help)
  [[ -z "${2:-}" ]] && { echo "Usage: dr help <name>"; exit 1; }
  show_help "$2"
  ;;

docs | details)
  [[ -z "${2:-}" ]] && { echo "Usage: dr docs <name>"; exit 1; }
  show_docs "$2"
  ;;
```

---

#### Collection Management

All collection commands check prerequisites and helper availability:

```bash
import)
  check_prerequisites
  [[ ! command -v import_collection ]] && exit 1
  # Parse arguments for --preview, --pick
  import_collection "$source" "$collection_name"
  ;;

export)
  check_prerequisites
  [[ ! command -v export_collection ]] && exit 1
  export_collection "$2" "$3" "$include_git"
  ;;

collections)
  check_prerequisites
  case "${2:-list}" in
    list | -l) list_collections ;;
    list:details | -L) list_collections true ;;
    remove) remove_collection "$3" "$force" ;;
  esac
  ;;
```

---

#### Utility Commands

```bash
-v | --version | version)
  echo "dr version $DRUN_VERSION"
  exit 0
  ;;

"" | -h | --help)
  # Display comprehensive help text
  echo "dr <command> [args...]"
  echo "Commands..."
  exit 0
  ;;

*)
  # Default: run as script
  if [[ -n "${1:-}" ]]; then
    run_script "$@"
  else
    echo "Error: No command provided" >&2
    exit 1
  fi
  ;;
```

---

## Helper Integration

### Dynamic Sourcing Pattern

```bash
HELPER_PATH="$DR_CONFIG/helpers/helper.sh"
# shellcheck disable=SC1090
[[ -f "$HELPER_PATH" ]] && source "$HELPER_PATH"
```

### Helper Availability Checks

```bash
if [[ $(type -t function_name) == "function" ]]; then
  function_name args
else
  echo "Error: Helper not available" >&2
  exit 1
fi
```

### Currently Sourced Helpers

1. `lint.sh` - ShellCheck integration
2. `aliases.sh` - Alias management
3. `config.sh` - Configuration management
4. `collections.sh` - Collection operations (via command checks)

---

## Error Handling Patterns

### Input Validation

```bash
[[ -z "${2:-}" ]] && {
  echo "Usage: dr command <required-arg>"
  exit 1
}
```

### Command Availability

```bash
command -v tool >/dev/null 2>&1 || {
  echo "Error: 'tool' not found"
  exit 1
}
```

### File Operations

```bash
if [[ ! -f "$file" ]]; then
  echo "Error: File not found: $file" >&2
  exit 1
fi
```

### Editor Validation

```bash
if [[ -z "$EDITOR" ]] || ! command -v "$EDITOR" >/dev/null 2>&1; then
  echo "Error: No valid editor found" >&2
  exit 1
fi
```

---

## Related Documentation

- [Collections API](collections-api.md) - Collection management functions
- [Script Resolution](../03-implementation/script-resolution.md) - How scripts are found
- [Move/Rename Algorithm](../03-implementation/move-rename.md) - Detailed move logic
- [Command Flow](../01-architecture/control-flow.md) - Command routing details
