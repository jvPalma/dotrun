# Script Resolution Implementation

**Function**: `find_script_file()`
**Location**: `dr` lines 171-212
**Complexity**: Medium
**Called By**: All script operations (add, edit, move, run, help, docs)

## Purpose

Locate executable script files by name or path, with validation for permissions and symlink integrity.

## Algorithm Overview

```
Input: query (script name or path)
       ↓
┌──────────────────────┐
│ Check if query       │
│ contains "/" ?       │
└──────┬───────────────┘
       │
       ├── YES → Phase 1: Explicit Path Match
       │         • Construct: $BIN_DIR/$query.sh
       │         • Check if file exists
       │         • Validate executable
       │         • Validate not broken symlink
       │         • Return path OR continue to Phase 2
       │
       └── NO  → Phase 2: Recursive Basename Search
                 • Extract basename: $(basename $query).sh
                 • Search: find $BIN_DIR -name basename
                 • Take first match
                 • Validate executable
                 • Validate not broken symlink
                 • Return path OR return empty
```

## Detailed Implementation

### Phase 1: Explicit Path Match

**Condition**: Query contains `/` character

```bash
if [[ "$query" == */* ]]; then
  local exact="$BIN_DIR/$query.sh"
  if [[ -f "$exact" ]]; then
    # Validation checks
    if [[ ! -x "$exact" ]]; then
      echo "Error: Script '$exact' is not executable" >&2
      return 1
    fi
    if [[ -L "$exact" ]] && ! readlink -e "$exact" >/dev/null 2>&1; then
      echo "Error: Script '$exact' is a broken symlink" >&2
      return 1
    fi
    echo "$exact"
    return
  fi
fi
```

**Examples**:

```bash
find_script_file "git/cleanup"
# Looks for: $BIN_DIR/git/cleanup.sh
# Returns: /home/user/.config/dotrun/bin/git/cleanup.sh

find_script_file "team/deploy/staging"
# Looks for: $BIN_DIR/team/deploy/staging.sh
# Returns: /home/user/.config/dotrun/bin/team/deploy/staging.sh
```

**Performance**: O(1) - Direct file check

**Advantages**:

- Fast lookup for categorized scripts
- Supports deep folder hierarchies
- Unambiguous (exact path specified)

**Limitations**:

- User must remember folder structure
- More typing required

---

### Phase 2: Recursive Basename Search

**Condition**: Fallback if Phase 1 doesn't find script, or query has no `/`

```bash
local base
base="$(basename "$query").sh"
local found_file
found_file=$(find "$BIN_DIR" -type f -name "$base" 2>/dev/null | head -n 1)

if [[ -n "$found_file" ]]; then
  # Validation checks
  if [[ ! -x "$found_file" ]]; then
    echo "Error: Script '$found_file' is not executable" >&2
    return 1
  fi
  if [[ -L "$found_file" ]] && ! readlink -e "$found_file" >/dev/null 2>&1; then
    echo "Error: Script '$found_file' is a broken symlink" >&2
    return 1
  fi
  echo "$found_file"
fi
```

**Examples**:

```bash
find_script_file "deploy"
# Searches: find $BIN_DIR -name "deploy.sh"
# Could match: bin/deploy.sh OR bin/team/deploy.sh OR bin/docker/deploy.sh
# Returns: First match found

find_script_file "cleanup"
# Searches: find $BIN_DIR -name "cleanup.sh"
# Returns: First match (could be anywhere in tree)
```

**Performance**: O(n) where n = number of files in `$BIN_DIR`

**Advantages**:

- Convenient for top-level scripts
- No need to remember paths
- Quick typing

**Limitations**:

- Ambiguous if multiple scripts have same name
- Slower for large script collections
- First match wins (may not be intended script)

---

## Validation Checks

### 1. Executable Permission Check

```bash
if [[ ! -x "$found_file" ]]; then
  echo "Error: Script '$found_file' is not executable" >&2
  return 1
fi
```

**Purpose**: Prevent execution of non-executable files

**Security**: Catches scripts with incorrect permissions

**User Feedback**: Clear error message with file path

**Resolution**:

```bash
chmod +x /path/to/script.sh
```

---

### 2. Broken Symlink Check

```bash
if [[ -L "$found_file" ]] && ! readlink -e "$found_file" >/dev/null 2>&1; then
  echo "Error: Script '$found_file' is a broken symlink" >&2
  return 1
fi
```

**Purpose**: Detect and report broken symbolic links

**Security**: Prevents cryptic errors from broken links

**Detection Method**:

- `[[ -L "$file" ]]` - Check if file is a symlink
- `readlink -e "$file"` - Follow symlink and verify target exists

**Common Causes**:

- Script was moved/deleted but symlink wasn't updated
- Collection was removed but symlinks remain
- Network path no longer accessible

**User Feedback**: Explicit "broken symlink" error

**Resolution**:

```bash
# Remove broken symlink
rm /path/to/broken/symlink.sh

# Or fix target
ln -sf /correct/target.sh /path/to/symlink.sh
```

---

## Return Values

### Success Case

**Output**: Absolute path to script file (stdout)

```
/home/user/.config/dotrun/bin/scriptname.sh
```

**Exit Code**: 0 (implicit)

**Usage**:

```bash
local file
file=$(find_script_file "scriptname")
if [[ -n "$file" ]]; then
  # Use $file
fi
```

---

### Failure Cases

#### Script Not Found

**Output**: Nothing (empty stdout)

**Exit Code**: 0 (no error, just not found)

**Calling Code Handles**:

```bash
file=$(find_script_file "$1")
if [[ -z "$file" ]]; then
  echo "Error: Script '$1' not found" >&2
  echo "Use 'dr -l' to list available scripts" >&2
  exit 1
fi
```

---

#### Not Executable

**Output**: Error message to stderr

```
Error: Script '/path/to/script.sh' is not executable
```

**Exit Code**: 1

**Calling Code**: Propagates error to user

---

#### Broken Symlink

**Output**: Error message to stderr

```
Error: Script '/path/to/script.sh' is a broken symlink
```

**Exit Code**: 1

**Calling Code**: Propagates error to user

---

## Edge Cases

### 1. Multiple Scripts with Same Name

**Scenario**:

```
bin/deploy.sh
bin/docker/deploy.sh
bin/kubernetes/deploy.sh
```

**Query**: `find_script_file "deploy"`

**Result**: Returns **first match** from `find` command (order not guaranteed)

**Solution**: Use explicit path

```bash
find_script_file "docker/deploy"   # Unambiguous
```

---

### 2. Script Name Contains Spaces

**Scenario**: `bin/my script.sh`

**Problem**: Won't be found due to name validation

**Validation**: `validate_script_name()` rejects spaces

**Solution**: Rename script to use dashes or underscores

```bash
mv "bin/my script.sh" "bin/my-script.sh"
```

---

### 3. Hidden Scripts (dot-prefix)

**Scenario**: `bin/.hidden-script.sh`

**Behavior**: `find` will locate it (finds hidden files by default)

**Recommendation**: Avoid dot-prefix for scripts (unconventional)

---

### 4. Circular Symlinks

**Scenario**:

```bash
ln -s script-a.sh script-b.sh
ln -s script-b.sh script-a.sh
```

**Detection**: `readlink -e` fails on circular links

**Result**: Caught by broken symlink check

**Error**: "Script is a broken symlink"

---

### 5. Permission Denied

**Scenario**: `bin/script.sh` exists but is not readable

**Behavior**:

- `[[ -f "$file" ]]` succeeds
- `[[ -x "$file" ]]` fails

**Error**: "Script is not executable"

**Resolution**: `chmod +x script.sh`

---

### 6. Case Sensitivity

**Behavior**: Case-sensitive on Linux/macOS, potentially insensitive on macOS (APFS)

**Example**:

```bash
# On Linux:
find_script_file "Deploy"  # Won't find "deploy.sh"

# On macOS (APFS case-insensitive):
find_script_file "Deploy"  # May find "deploy.sh"
```

**Recommendation**: Use consistent lowercase naming

---

## Performance Considerations

### Best Case: O(1)

**Scenario**: Explicit path with `/`, file exists, valid

**Time**: ~1ms (single file stat)

**Example**:

```bash
find_script_file "git/cleanup"
```

---

### Worst Case: O(n)

**Scenario**: Simple name, file is last in traversal order

**Time**: ~10-100ms for 1000 scripts

**Example**:

```bash
find_script_file "script-at-end"
```

---

### Optimization Strategies

#### Strategy 1: Use Folder Organization

```bash
# Slower (searches all)
dr deploy

# Faster (direct path)
dr docker/deploy
```

#### Strategy 2: Cache Script Locations

**Not Currently Implemented**

Potential improvement:

```bash
# Build cache on shell startup
SCRIPT_CACHE["deploy"]="/path/to/bin/deploy.sh"
SCRIPT_CACHE["docker/deploy"]="/path/to/bin/docker/deploy.sh"

# Lookup from cache
echo "${SCRIPT_CACHE[$query]}"
```

**Trade-offs**:

- Faster lookups
- More complex code
- Cache invalidation complexity
- Startup time cost

---

## Integration Points

### Called By Functions

1. **add_script()** - Check if script exists
2. **edit_script()** - Find script to edit
3. **edit_docs()** - Find script to get doc path
4. **show_help()** - Find script to extract docs
5. **show_docs()** - Find script to get doc path
6. **move_script()** - Find source script
7. **run_script()** - Find script to execute

### Dependencies

**External Commands**:

- `basename` - Extract filename from path
- `find` - Search for files
- `readlink` - Validate symlinks

**Bash Builtins**:

- `[[` - Conditional tests
- `return` - Exit function with status
- `echo` - Output results

**Global Variables**:

- `$BIN_DIR` - Root directory for scripts

---

## Testing Scenarios

### Basic Functionality

```bash
# Test 1: Find top-level script
find_script_file "hello"
# Expected: /path/to/bin/hello.sh

# Test 2: Find categorized script (explicit)
find_script_file "git/cleanup"
# Expected: /path/to/bin/git/cleanup.sh

# Test 3: Find categorized script (implicit)
find_script_file "cleanup"
# Expected: /path/to/bin/git/cleanup.sh (if unique)

# Test 4: Script not found
find_script_file "nonexistent"
# Expected: (empty output)

# Test 5: Non-executable script
touch bin/test.sh  # No chmod +x
find_script_file "test"
# Expected: Error message about permissions
```

### Edge Cases

```bash
# Test 6: Broken symlink
ln -s /nonexistent/target bin/broken.sh
find_script_file "broken"
# Expected: Error message about broken symlink

# Test 7: Multiple matches (ambiguous)
touch bin/deploy.sh bin/docker/deploy.sh
find_script_file "deploy"
# Expected: Returns one (first found)

# Test 8: Deep nesting
mkdir -p bin/a/b/c/d
touch bin/a/b/c/d/deep.sh && chmod +x bin/a/b/c/d/deep.sh
find_script_file "a/b/c/d/deep"
# Expected: /path/to/bin/a/b/c/d/deep.sh
```

---

## Related Documentation

- [API Reference: dr-main.md](../02-api-reference/dr-main.md#find_script_file) - Function signature
- [Architecture: Overview](../01-architecture/overview.md#script-execution-flow) - How resolution fits in
- [Testing: Test Scenarios](../05-testing/test-scenarios.md) - Comprehensive test cases
- [Troubleshooting: Common Errors](../07-troubleshooting/common-errors.md) - Resolution failures
