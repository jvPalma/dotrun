# Fix ZSH Recursive Completion - Design Document

## Overview

This document details the technical design for fixing the ZSH autocomplete recursive search feature in dotrun.

## Architecture Context

### Current Completion System Structure

```
~/.local/share/dotrun/shell/
├── bash/
│   ├── dr_completion.bash      # Standard bash completion (445 lines)
│   └── dr_completion_ble.sh    # Enhanced bash completion for ble.sh (152 lines)
├── zsh/
│   └── dr_completion.zsh       # ZSH completion (936 lines) ← FIX HERE
└── fish/
    └── dr_completion.fish      # Fish completion
```

### Loading Chain

```
~/.bashrc or ~/.zshrc
└── source ~/.drrc
    └── source ~/.local/share/dotrun/.dr_config_loader
        └── source ~/.local/share/dotrun/shell/zsh/dr_completion.zsh
            └── compdef _dr dr (registers completion function)
```

### Key Functions in ZSH Completion

| Function                      | Lines   | Purpose                                       |
| ----------------------------- | ------- | --------------------------------------------- |
| `_dr()`                       | 35-930  | Main completion function                      |
| `_dr_search_recursive()`      | 253-319 | Searches all scripts/folders matching pattern |
| `_dr_emit_recursive_search()` | 323-379 | Formats and emits search results              |
| `_dr_emit_context()`          | 159-182 | Emits hierarchical folder/script listings     |
| `_dr_add_commands_with_tag()` | 100-112 | Adds command completions with zstyle tags     |

## Technical Analysis

### Problem: Why Completions Are Filtered

**ZSH Completion Flow:**

```
1. User types: dr tab-t<TAB>
2. ZSH calls _dr() with:
   - CURRENT=2 (position of word being completed)
   - words=(dr tab-t) (all words on command line)
3. _dr() at POSITION 2 detects pattern "tab-t" (not empty, not flag)
4. Calls _dr_emit_recursive_search("tab-t")
5. _dr_search_recursive finds matches:
   - folder1/tab-testing
   - folder1/folder2/folder3/tab-testing
6. _dr_emit_recursive_search calls compadd with these matches
7. ZSH's completion system compares "tab-t" against "folder1/tab-testing"
8. Since "tab-t" is NOT a prefix of "folder1/tab-testing", ZSH filters it out
9. No completions shown to user
```

**The Core Issue:**

ZSH's `compadd` by default only shows completions where the user's input is a prefix of the completion text. Our recursive search intentionally matches on **basenames** (final component), not full paths.

### Solution: The `-U` Flag

The `-U` flag tells `compadd` to add completions **unconditionally**, without checking if they match the current word. This is appropriate here because:

1. `_dr_search_recursive()` already performs intelligent matching:
   - Case-insensitive comparison on basenames
   - Priority 1: Prefix matches (highest)
   - Priority 2: Substring matches
   - Results sorted by priority, then depth, then alphabetically

2. Other functions in the same file already use `-U`:
   - `_dr_add_folders()` at line 191
   - `_dr_add_scripts()` at line 224

### Detailed Code Changes

#### Change 1: Add `-U` to `_dr_emit_recursive_search()`

**Location:** `core/shared/dotrun/shell/zsh/dr_completion.zsh`, lines 364-378

**Current Code:**

```zsh
_dr_emit_recursive_search() {
  local pattern="$1"
  # ... search and build arrays ...

  if ((${#matches[@]})); then
    echo ">>> Adding ${#matches[@]} completions..." >>/tmp/dr_completion_debug.log
    # BUG: Missing -U flag causes ZSH to filter based on prefix matching
    compadd -M 'r:|[/]=* r:|=*' -d displays -a -- matches
    echo ">>> Done adding completions with compadd" >>/tmp/dr_completion_debug.log
    return 0
  else
    echo ">>> NO MATCHES - returning 1" >>/tmp/dr_completion_debug.log
    return 1
  fi
}
```

**Option A - Simple Fix (Recommended):**

```zsh
_dr_emit_recursive_search() {
  local pattern="$1"
  # ... search and build arrays ...

  if ((${#matches[@]})); then
    # -U: Add unconditionally (we already did matching in _dr_search_recursive)
    compadd -U -M 'r:|[/]=* r:|=*' -d displays -a -- matches
    return 0
  else
    return 1
  fi
}
```

**Option B - With Proper Tagging (Better Colors/Grouping):**

```zsh
_dr_emit_recursive_search() {
  local pattern="$1"
  local -a matches displays

  # ... populate matches and displays from _dr_search_recursive ...

  if ((${#matches[@]})); then
    # Separate folders and scripts for proper zstyle tagging
    local -a folder_matches folder_displays script_matches script_displays
    local i
    for i in {1..${#matches[@]}}; do
      if [[ "${matches[$i]}" == */ ]]; then
        folder_matches+=("${matches[$i]}")
        folder_displays+=("${displays[$i]}")
      else
        script_matches+=("${matches[$i]}")
        script_displays+=("${displays[$i]}")
      fi
    done

    # Use _wanted for proper tag registration (enables zstyle colors)
    ((${#folder_matches[@]})) \
      && _wanted folders expl 'folders' compadd -U -S '' -d folder_displays -a -- folder_matches
    ((${#script_matches[@]})) \
      && _wanted scripts expl 'scripts' compadd -U -d script_displays -a -- script_matches
    return 0
  else
    return 1
  fi
}
```

**Recommendation:** Start with Option A for simplicity. Option B can be added later if better color/grouping is needed.

#### Change 2: Remove Debug Logging

**Current State:** 20+ debug statements write to `/tmp/dr_completion_debug.log` on every TAB press.

**Locations to Remove/Modify:**

| Lines              | Description                       |
| ------------------ | --------------------------------- |
| 37-44              | Main `_dr()` entry logging block  |
| 328                | `_dr_emit_recursive_search` entry |
| 361-362            | Match count and details           |
| 365, 373, 376      | Completion status messages        |
| 570-576            | POSITION 2 entry block            |
| 580, 591, 596, 599 | POSITION 2 branch logging         |
| 621-629            | POSITION 3 entry block            |
| 633, 641           | POSITION 3 branch logging         |

**Option A - Complete Removal:**
Delete all lines that write to `/tmp/dr_completion_debug.log`.

**Option B - Conditional Logging:**

```zsh
# At top of file, define helper
_dr_debug() {
  [[ -n "${DR_COMPLETION_DEBUG:-}" ]] && echo "$@" >>/tmp/dr_completion_debug.log
}

# Replace all direct writes with:
_dr_debug ">>> _dr_emit_recursive_search called with pattern='$pattern'"
```

**Recommendation:** Option A (complete removal) for production. Debug logging can be re-added during development if needed.

#### Change 3: Fix Shellcheck Declaration

**Location:** Line 2

**Current:**

```bash
# shellcheck shell=bash disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
```

**Fixed:**

```bash
# shellcheck shell=zsh disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
```

**Rationale:** The file uses ZSH-specific syntax:

- `${(L)var}` - ZSH parameter expansion modifiers
- `compdef`, `_wanted`, `compadd` - ZSH completion builtins
- `${words[@]}`, `$CURRENT` - ZSH completion variables

#### Change 4: Fix Return Value at Line 597

**Current:**

```zsh
if [[ -n "$current_word" && "$current_word" != -* ]]; then
  _dr_emit_recursive_search "$current_word"
  # Return immediately - no other completions allowed
  echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
  return  # ← BUG: No return code, ignores _dr_emit_recursive_search result
```

**Fixed:**

```zsh
if [[ -n "$current_word" && "$current_word" != -* ]]; then
  _dr_emit_recursive_search "$current_word" && return 0 || return 1
```

**Rationale:**

- `_dr_emit_recursive_search` returns 0 (matches found) or 1 (no matches)
- This return value should propagate to inform ZSH whether completion succeeded
- The `&& return 0 || return 1` pattern preserves the exit status

## Testing Strategy

### Manual Test Cases

```bash
# Setup: Create test scripts
dr set folder1/folder2/folder3/tab-testing
dr set folder1/tab-testing
dr set prStats
dr set git/status/prStats

# Test 1: Root-level partial match
dr tab-t<TAB>
# Expected: Shows folder1/tab-testing, folder1/folder2/folder3/tab-testing

# Test 2: Root-level exact match (basename)
dr tab-testing<TAB>
# Expected: Shows folder1/tab-testing, folder1/folder2/folder3/tab-testing

# Test 3: Prefix match across folders
dr pr<TAB>
# Expected: Shows prStats, git/status/prStats

# Test 4: Hierarchical navigation unchanged
dr folder1/<TAB>
# Expected: Shows folder2/, tab-testing

# Test 5: Empty root
dr <TAB>
# Expected: Shows folders, scripts, hint (hierarchical view)

# Test 6: Namespace commands unchanged
dr -s <TAB>
# Expected: Shows set, edit, help, move, remove + recursive search

# Test 7: No matches
dr nonexistent<TAB>
# Expected: No completions shown
```

### Debug Verification

```bash
# Before fix: Debug log grows
dr tab<TAB>
ls -la /tmp/dr_completion_debug.log
# Shows file with recent writes

# After fix: No debug log writes (unless DR_COMPLETION_DEBUG set)
rm /tmp/dr_completion_debug.log
dr tab<TAB>
ls -la /tmp/dr_completion_debug.log
# File should not exist (or be from before)
```

## Performance Considerations

### Current Performance Issue

Every TAB press:

1. Runs `find` command recursively through scripts directory
2. Runs another `find` for folders
3. Writes 5-10 debug log entries to disk

### After Fix

1. `find` commands unchanged (necessary for search)
2. No disk I/O for debug logging
3. Slightly more array operations if using Option B (with tagging)

### Future Optimization (Not in Scope)

Caching could improve performance for large script collections:

```zsh
# Cache scripts list with timestamp
_dr_cache_scripts() {
  local cache_file="/tmp/dr_scripts_cache"
  local scripts_dir="$BIN_DIR"

  # Refresh if cache older than 60 seconds
  if [[ ! -f "$cache_file" ]] \
    || [[ $(stat -c %Y "$scripts_dir") -gt $(stat -c %Y "$cache_file") ]]; then
    find "$scripts_dir" -type f -name "*.sh" >"$cache_file"
  fi

  cat "$cache_file"
}
```

This is out of scope for this change but noted for future enhancement.

## Rollback Plan

If issues are discovered:

1. The change is isolated to one file: `shell/zsh/dr_completion.zsh`
2. Previous version can be restored from git
3. No database migrations or external dependencies

```bash
# Rollback command
git checkout HEAD~1 -- core/shared/dotrun/shell/zsh/dr_completion.zsh
```

## Dependencies

- No external dependencies
- No changes to main `dr` script
- No changes to bash or fish completion
- Compatible with all ZSH versions that support compdef (ZSH 4.3+)
