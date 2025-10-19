# Adding New Commands to DotRun

**Guide Level**: Intermediate
**Estimated Time**: 30-60 minutes
**Prerequisites**: Understanding of Bash scripting

## Overview

This guide walks through adding a new command to DotRun, from design to testing. We'll use a real example: adding a `validate` command that checks script health.

## Command Anatomy

Every DotRun command consists of:

1. **Case Branch** - Router entry in main case statement
2. **Handler Function** - Optional, for complex logic
3. **Helper Module** - Optional, for reusable functionality
4. **Validation** - Input checking and error handling
5. **Help Text** - Usage documentation
6. **Testing** - Manual validation procedures

## Step-by-Step: Adding `validate` Command

### Step 1: Design the Command

**Purpose**: Check scripts for common issues (ShellCheck errors, missing docs, etc.)

**Usage**:

```bash
dr validate <script-name>    # Validate specific script
dr validate --all             # Validate all scripts
```

**Output**:

```
✓ hello: Passed all checks
✗ deploy: ShellCheck errors (3)
⚠ cleanup: Missing markdown documentation
```

---

### Step 2: Identify Requirements

**What it needs**:

- Script resolution (use existing `find_script_file()`)
- ShellCheck integration (use existing `lint.sh` helper)
- Documentation checking (new logic)
- Summary output (new logic)

**Dependencies**:

- ShellCheck (optional, warn if not available)
- find command (standard)
- awk (standard)

---

### Step 3: Create Handler Function

**Location**: Add to `dr` before the case statement (around line 480)

```bash
# Validate script for common issues
validate_script() {
  local script_name="$1"
  local issues=0

  # Find script file
  local file
  file=$(find_script_file "$script_name")
  if [[ -z "$file" ]]; then
    echo "Error: Script '$script_name' not found" >&2
    return 1
  fi

  echo "Validating $script_name..."

  # Check 1: ShellCheck
  if command -v shellcheck >/dev/null 2>&1; then
    if ! shellcheck "$file" >/dev/null 2>&1; then
      local error_count
      error_count=$(shellcheck "$file" 2>&1 | grep -c "^In ")
      echo "  ✗ ShellCheck errors: $error_count"
      ((issues++))
    else
      echo "  ✓ ShellCheck passed"
    fi
  else
    echo "  ⚠ ShellCheck not available (install for linting)"
  fi

  # Check 2: Inline documentation
  if ! grep -q "^$DOC_TOKEN" "$file"; then
    echo "  ✗ Missing inline documentation (### DOC markers)"
    ((issues++))
  else
    echo "  ✓ Inline documentation present"
  fi

  # Check 3: Markdown documentation
  local rel_path="${file#"$BIN_DIR"/}"
  local doc_file="$DOC_DIR/${rel_path%.sh}.md"
  if [[ ! -f "$doc_file" ]]; then
    echo "  ⚠ Missing markdown documentation"
    echo "    Create with: dr edit:docs $script_name"
  else
    echo "  ✓ Markdown documentation present"
  fi

  # Check 4: Executable permission
  if [[ ! -x "$file" ]]; then
    echo "  ✗ Not executable"
    ((issues++))
  else
    echo "  ✓ Executable permission set"
  fi

  # Check 5: Shebang
  if ! head -1 "$file" | grep -q "^#!/"; then
    echo "  ✗ Missing shebang (#!/usr/bin/env bash)"
    ((issues++))
  else
    echo "  ✓ Shebang present"
  fi

  echo ""
  if [[ $issues -eq 0 ]]; then
    echo "✓ $script_name: All checks passed"
    return 0
  else
    echo "✗ $script_name: $issues issue(s) found"
    return 1
  fi
}

# Validate all scripts
validate_all_scripts() {
  local total=0
  local passed=0
  local failed=0

  echo "Validating all scripts..."
  echo ""

  while IFS= read -r -d '' file; do
    rel_path="${file#"$BIN_DIR"/}"
    script_name="${rel_path%.sh}"

    ((total++))
    if validate_script "$script_name" >/dev/null 2>&1; then
      echo "  ✓ $script_name"
      ((passed++))
    else
      echo "  ✗ $script_name"
      ((failed++))
    fi
  done < <(find "$BIN_DIR" -type f -name "*.sh" -print0 | sort -z)

  echo ""
  echo "Summary: $total scripts, $passed passed, $failed failed"

  [[ $failed -eq 0 ]] && return 0 || return 1
}
```

---

### Step 4: Add Case Branch

**Location**: Add to case statement in `dr` (after line 555, before `*)` case)

```bash
validate)
  if [[ -z "${2:-}" ]]; then
    echo "Usage: dr validate <name>"
    echo "       dr validate --all"
    echo ""
    echo "Validates script for common issues:"
    echo "  • ShellCheck errors"
    echo "  • Missing documentation"
    echo "  • Executable permissions"
    echo "  • Shebang presence"
    exit 1
  fi

  if [[ "$2" == "--all" ]]; then
    validate_all_scripts
  else
    validate_script "$2"
  fi
  ;;
```

---

### Step 5: Update Help Text

**Location**: Update the help case in `dr` (lines 945-1011)

Add to the commands list:

```bash
echo "  validate <name>     Validate script for common issues"
echo "  validate --all      Validate all scripts"
```

Add to examples section:

```bash
echo "  dr validate deploy                # Check specific script"
echo "  dr validate --all                 # Check all scripts"
```

---

### Step 6: Add Tab Completion

**For Bash**: Edit `drun_completion.bash`

Find the completion function and add to the commands list:

```bash
local commands="
  -l -L add edit edit:docs move rename mv help docs details
  validate
  import export collections team aliases config
  yadm-init --help --version -h -v version
"
```

**For Zsh**: Edit `drun_completion.zsh`

Add to the commands array:

```bash
'validate:Validate script for common issues'
```

**For Fish**: Edit `drun_completion.fish`

Add to the complete options:

```fish
complete -c dr -n '__fish_drun_needs_command' -a 'validate' -d 'Validate script'
```

---

### Step 7: Test the Command

#### Manual Test Suite

**Test 1: Basic validation**

```bash
# Create test script
dr add test-validate

# Add content without docs
cat > ~/.config/dotrun/bin/test-validate.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "test"
EOF

# Run validation
dr validate test-validate

# Expected: Should warn about missing DOC markers
```

**Test 2: Validate all**

```bash
dr validate --all

# Expected: Shows summary of all scripts
```

**Test 3: Help text**

```bash
dr validate

# Expected: Shows usage help
```

**Test 4: Non-existent script**

```bash
dr validate nonexistent

# Expected: Error message, exit code 1
```

**Test 5: Tab completion**

```bash
dr vali<TAB>

# Expected: Completes to "validate"
```

---

### Step 8: Handle Edge Cases

#### Edge Case 1: Permission denied on script

**Scenario**: Script exists but not readable

**Handler**:

```bash
if [[ ! -r "$file" ]]; then
  echo "  ✗ Cannot read file (permission denied)"
  ((issues++))
  return 1
fi
```

#### Edge Case 2: ShellCheck not installed

**Already Handled**: Warns but continues validation

#### Edge Case 3: Binary/non-text files

**Handler**:

```bash
if ! file "$file" | grep -q "text"; then
  echo "  ⚠ Not a text file (skipping checks)"
  return 0
fi
```

---

## Complete Example: Adding `stats` Command

Let's add another command that shows repository statistics.

### Handler Function

```bash
show_stats() {
  local script_count docs_count collection_count

  echo "DotRun Statistics"
  echo "═════════════════"
  echo ""

  # Count scripts
  script_count=$(find "$BIN_DIR" -type f -name "*.sh" | wc -l)
  echo "Scripts:     $script_count"

  # Count docs
  docs_count=$(find "$DOC_DIR" -type f -name "*.md" 2>/dev/null | wc -l)
  echo "Docs:        $docs_count"

  # Count collections
  if [[ -d "$COLLECTIONS_DIR" ]]; then
    collection_count=$(find "$COLLECTIONS_DIR" -maxdepth 1 -type d | tail -n +2 | wc -l)
  else
    collection_count=0
  fi
  echo "Collections: $collection_count"

  # Disk usage
  local disk_usage
  disk_usage=$(du -sh "$DR_CONFIG" 2>/dev/null | cut -f1)
  echo "Disk usage:  $disk_usage"

  # Most used scripts (if history available)
  echo ""
  echo "Recently modified scripts:"
  find "$BIN_DIR" -type f -name "*.sh" -printf "%T@ %p\n" |
    sort -rn |
    head -5 |
    while read -r timestamp file; do
      rel_path="${file#"$BIN_DIR"/}"
      echo "  • ${rel_path%.sh}"
    done
}
```

### Case Branch

```bash
stats)
  show_stats
  ;;
```

### Help Text Addition

```bash
echo "  stats               Show repository statistics"
```

### Tab Completion Addition

Add "stats" to the commands lists in all three completion files.

---

## Best Practices

### 1. Validation First

Always validate input before processing:

```bash
if [[ -z "${2:-}" ]]; then
  echo "Usage: ..." >&2
  exit 1
fi
```

### 2. Clear Error Messages

Include actionable advice:

```bash
echo "Error: Script '$name' not found" >&2
echo "Use 'dr -l' to list available scripts" >&2
```

### 3. Graceful Degradation

Handle missing optional dependencies:

```bash
if command -v tool >/dev/null 2>&1; then
  # Use tool
else
  echo "⚠ Tool not available (optional feature disabled)"
fi
```

### 4. Consistent Return Codes

- `0`: Success
- `1`: General error
- `2`: Invalid usage (unused but reserved)

### 5. Help Text Format

Match existing style:

```bash
echo "Usage: dr command <arg> [options]"
echo ""
echo "Description of what command does."
echo ""
echo "Options:"
echo "  --flag    Description"
echo ""
echo "Examples:"
echo "  dr command example"
```

---

## Testing Checklist

- [ ] Command works with valid input
- [ ] Command fails gracefully with invalid input
- [ ] Help text displays correctly
- [ ] Tab completion works in all shells (bash/zsh/fish)
- [ ] Error messages are clear and actionable
- [ ] Works with both simple and categorized scripts
- [ ] Handles edge cases (permissions, missing files, etc.)
- [ ] No regression in existing commands
- [ ] Documentation updated (help text)
- [ ] Tested in all supported shells

---

## Integration with Helpers

If command needs significant shared logic, create a helper:

### Step 1: Create Helper Module

**Location**: `helpers/stats.sh`

```bash
#!/usr/bin/env bash
# Statistics helper for DotRun

# Ensure required variables are set
DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
BIN_DIR="${BIN_DIR:-$DR_CONFIG/bin}"
DOC_DIR="${DOC_DIR:-$DR_CONFIG/docs}"

get_script_count() {
  find "$BIN_DIR" -type f -name "*.sh" | wc -l
}

get_docs_count() {
  find "$DOC_DIR" -type f -name "*.md" 2>/dev/null | wc -l
}

# Export functions
export -f get_script_count
export -f get_docs_count
```

### Step 2: Source Helper in dr

Add near the top (around line 75):

```bash
STATS_HELPER="$DR_CONFIG/helpers/stats.sh"
[[ -f "$STATS_HELPER" ]] && source "$STATS_HELPER"
```

### Step 3: Use Helper Functions

```bash
show_stats() {
  if [[ $(type -t get_script_count) != "function" ]]; then
    echo "Error: Stats helper not available" >&2
    exit 1
  fi

  local script_count=$(get_script_count)
  local docs_count=$(get_docs_count)

  echo "Scripts: $script_count"
  echo "Docs: $docs_count"
}
```

---

## Common Pitfalls

### Pitfall 1: Not Checking Arguments

**Bad**:

```bash
newcommand)
  do_something "$2"
  ;;
```

**Good**:

```bash
newcommand)
  [[ -z "${2:-}" ]] && {
    echo "Usage: dr newcommand <arg>"
    exit 1
  }
  do_something "$2"
  ;;
```

### Pitfall 2: Breaking Existing Commands

**Prevention**: Test all existing commands after changes

```bash
# Quick smoke test
dr -l
dr add test-temp
dr edit:docs test-temp
dr help test-temp
dr test-temp
dr move test-temp test-temp2
dr test-temp2
```

### Pitfall 3: Inconsistent Naming

**Bad**: `dr validate_all`
**Good**: `dr validate --all`

Follow existing patterns:

- Use hyphens for multi-word commands (`edit:docs`)
- Use flags for modes (`--all`, `--preview`)

### Pitfall 4: Not Updating Completions

Users expect tab completion for all commands. Update all three completion files.

---

## Advanced: Commands with Subcommands

For complex commands like `collections`, use nested case:

```bash
collections)
  check_prerequisites
  case "${2:-list}" in
    list | -l)
      list_collections
      ;;
    list:details | -L)
      list_collections true
      ;;
    remove)
      [[ -z "${3:-}" ]] && {
        echo "Usage: dr collections remove <name>"
        exit 1
      }
      remove_collection "$3" "$4"
      ;;
    *)
      echo "Usage: dr collections <command>"
      echo "Commands: list, list:details, remove"
      exit 1
      ;;
  esac
  ;;
```

---

## Version Bumping

After adding significant commands:

1. Update `DRUN_VERSION` in `dr`:

   ```bash
   DRUN_VERSION="1.1.0"  # Minor version bump for new features
   ```

2. Update README.md badge:

   ```markdown
   [![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](VERSION)
   ```

3. Document in CHANGELOG (if exists)

---

## Related Documentation

- [API Reference: dr-main.md](../02-api-reference/dr-main.md) - Existing functions
- [Architecture: Control Flow](../01-architecture/control-flow.md) - Command routing
- [Testing: Test Scenarios](../05-testing/test-scenarios.md) - Test procedures
- [Creating Helpers](creating-helpers.md) - Helper module guide
