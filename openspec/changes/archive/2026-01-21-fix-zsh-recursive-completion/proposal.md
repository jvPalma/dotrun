# Fix ZSH Recursive Completion

## Summary

Fix the ZSH autocomplete system to properly display all matching scripts when typing a partial name at the root level. Currently, typing `dr tab-t<TAB>` should show all scripts matching "tab-t" across all nested folders, but the matches are found internally then filtered out by zsh's default completion matching.

**Primary fix:** Add `-U` flag to `compadd` in `_dr_emit_recursive_search()` to bypass zsh's default prefix matching (our search function already performs intelligent matching).

**Secondary fixes:** Remove debug logging, fix shellcheck config, fix inconsistent return values.

## Why

### Current Behavior (Broken)

```bash
# User creates two scripts with same name in different folders
❯ dr set folder1/folder2/folder3/tab-testing
✓ Created new script: ~/.config/dotrun/scripts/folder1/folder2/folder3/tab-testing.sh

❯ dr set folder1/tab-testing
✓ Created new script: ~/.config/dotrun/scripts/folder1/tab-testing.sh

# When user tries to autocomplete, nothing shows up
❯ dr tab-t<TAB>
# (no completions shown)

# But the script runs (silently picks first match)
❯ dr tab-testing
Running folder1/tab-testing
```

### Expected Behavior

```bash
❯ dr tab-t<TAB>
(hint: -s/scripts, -a/aliases, -c/config, -col/collections)
📁 folder1/tab-testing
📁 folder1/folder2/folder3/tab-testing
```

The user should see ALL scripts matching their partial input, allowing them to select the correct one.

### Root Cause Analysis

**Primary Bug - Line 371 in `_dr_emit_recursive_search()`:**

```zsh
compadd -M 'r:|[/]=* r:|=*' -d displays -a -- matches
```

The search function `_dr_search_recursive()` correctly finds matches like `folder1/tab-testing`. However, zsh's completion system then compares the user's input `tab-t` against the full paths. Since `tab-t` is NOT a prefix of `folder1/tab-testing`, zsh filters them out.

**Evidence from debug logs:**

```
>>> _dr_emit_recursive_search called with pattern='tab-t'
>>> Found 2 matches
>>> Match: folder1/tab-testing
>>> Match: folder1/folder2/folder3/tab-testing
>>> Adding 2 completions...
>>> Done adding completions with compadd
```

The matches ARE found, but zsh's default matching removes them.

**Fix:** Add `-U` flag to `compadd` to add completions unconditionally (bypassing zsh's prefix check). Our search function already does intelligent case-insensitive matching on basenames with priority sorting.

### Additional Issues Found

1. **Debug logging in production** - 20+ locations writing to `/tmp/dr_completion_debug.log` on every TAB press
2. **Shellcheck config wrong** - Line 2 declares `shell=bash` but this is ZSH-specific code
3. **Inconsistent return values** - Line 597 has `return` without code, loses result from `_dr_emit_recursive_search`
4. **Missing `_wanted` tag** - Line 371 uses `compadd` directly without `_wanted`, bypassing zstyle colors/grouping

## What Changes

### 1. Fix Recursive Search Display (Critical)

**File:** `core/shared/dotrun/shell/zsh/dr_completion.zsh`

**Change Line 371 from:**

```zsh
compadd -M 'r:|[/]=* r:|=*' -d displays -a -- matches
```

**To (Option A - with `_wanted` for proper tagging):**

```zsh
# Separate folders and scripts for proper tagging
local -a folder_matches folder_displays script_matches script_displays
for i in {1..${#matches[@]}}; do
  if [[ "${matches[$i]}" == */ ]]; then
    folder_matches+=("${matches[$i]}")
    folder_displays+=("${displays[$i]}")
  else
    script_matches+=("${matches[$i]}")
    script_displays+=("${displays[$i]}")
  fi
done
((${#folder_matches[@]})) && _wanted folders expl 'folders' compadd -U -S '' -d folder_displays -a -- folder_matches
((${#script_matches[@]})) && _wanted scripts expl 'scripts' compadd -U -d script_displays -a -- script_matches
```

**Or (Option B - simpler, just add `-U`):**

```zsh
compadd -U -M 'r:|[/]=* r:|=*' -d displays -a -- matches
```

### 2. Remove Debug Logging

Remove all 20+ debug logging statements that write to `/tmp/dr_completion_debug.log`:

- Lines 37-44 (main function entry)
- Line 328 (recursive search entry)
- Lines 361-362 (match count and details)
- Lines 365, 373, 376 (completion status)
- Lines 570-576, 580, 591, 596, 599 (POSITION 2 logging)
- Lines 621-629, 633, 641 (POSITION 3 logging)

**Alternative:** Make debug logging conditional on `DR_COMPLETION_DEBUG` environment variable.

### 3. Fix Shellcheck Config

**Change Line 2 from:**

```bash
# shellcheck shell=bash disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
```

**To:**

```bash
# shellcheck shell=zsh disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
```

### 4. Fix Inconsistent Return Values

**Change Line 597 from:**

```zsh
_dr_emit_recursive_search "$current_word"
# Return immediately - no other completions allowed
echo "RETURNED from recursive search" >>/tmp/dr_completion_debug.log
return
```

**To:**

```zsh
_dr_emit_recursive_search "$current_word" && return 0 || return 1
```

## Impact

### Affected Files

**Modified:**

- `core/shared/dotrun/shell/zsh/dr_completion.zsh` - Main fix location (936 lines)

**Unchanged:**

- `core/shared/dotrun/shell/bash/dr_completion.bash` - Different implementation, no change needed
- `core/shared/dotrun/shell/bash/dr_completion_ble.sh` - Already works correctly
- `core/shared/dotrun/shell/fish/dr_completion.fish` - Different implementation

### Affected Specs

**New Capability:** `shell-completion`

This creates a new spec for shell completion behavior, as no existing spec covers tab completion.

### Benefits

- Users can discover scripts by partial name from anywhere in the hierarchy
- Disambiguation between multiple scripts with same basename
- Proper emoji and color display in recursive search results
- No more debug log pollution in `/tmp`
- Faster completion (no file I/O for debug logging)

### Risks

**Low risk** - Changes are contained to the completion file and don't affect script execution.

**Testing required:**

- Verify partial name matching works at root level
- Verify hierarchical navigation still works (`dr folder/<TAB>`)
- Verify namespace commands still work (`dr -s <TAB>`, `dr -a <TAB>`)
- Verify colors and emojis display correctly

## Validation

**Functional:**

- [ ] `dr tab<TAB>` shows `folder1/tab-testing`, `folder1/folder2/folder3/tab-testing`
- [ ] `dr tab-t<TAB>` shows same matches (partial prefix works)
- [ ] `dr <TAB>` shows root folders and scripts (hierarchical unchanged)
- [ ] `dr git/<TAB>` shows git folder contents (hierarchical unchanged)
- [ ] `dr nonexistent<TAB>` shows nothing (no false matches)
- [ ] Results display with emojis and colors

**Technical:**

- [ ] No writes to `/tmp/dr_completion_debug.log` in normal usage
- [ ] Shellcheck passes with `shell=zsh`
- [ ] `openspec validate fix-zsh-recursive-completion --strict` passes

## Dependencies

**Blocked By:** None

**Blocks:** None

**Related:**

- The main `dr` script uses `head -n 1` for ambiguous script names (silent first-match behavior)
- Completion should show all matches so user can disambiguate before execution

## Alternatives Considered

### Alternative 1: Change Matcher Spec Only

**Approach:** Modify `-M` matcher spec to allow basename matching

**Rejected Because:**

- Matcher specs are complex and may have unintended side effects
- The `-U` flag is cleaner and more explicit
- Other functions (`_dr_add_folders`, `_dr_add_scripts`) already use `-U` successfully

### Alternative 2: Change Search to Return Full Input

**Approach:** Have `_dr_search_recursive` transform results to match user input

**Rejected Because:**

- Would require returning `tab-t` → `folder1/tab-testing` mapping
- More complex implementation
- Loses full path display which is valuable for disambiguation

### Alternative 3: Keep Debug Logging Behind Flag

**Approach:** Keep all debug logging but gate behind `DR_COMPLETION_DEBUG=1`

**Considered:** This is a valid option if debugging is frequently needed. Could be implemented as:

```zsh
[[ -n "${DR_COMPLETION_DEBUG:-}" ]] && echo "..." >>/tmp/dr_completion_debug.log
```

## Success Criteria

- [ ] `dr <partial-name><TAB>` shows ALL matching scripts across ALL nested folders
- [ ] Results display with proper emojis (🚀 scripts, 📁 folders) and colors
- [ ] Results sorted by priority (prefix matches first) then depth (shallower first)
- [ ] No debug output to `/tmp/dr_completion_debug.log` in normal usage
- [ ] Existing completion behavior unchanged (hierarchical navigation, namespace commands)
- [ ] Shellcheck passes with correct shell type
