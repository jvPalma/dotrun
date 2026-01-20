# Fix ZSH Recursive Completion - Task List

## Task Organization

Tasks are organized into phases. Each task is designed to be small, verifiable, and deliver visible progress.

**Parallelizable tasks** are marked with 🔀
**Critical path tasks** have dependencies noted

---

## Phase 1: Core Bug Fix

### 1.1 Add `-U` Flag and `_wanted` Tags to Recursive Search Emit

- [x] 1.1.1 Open `core/shared/dotrun/shell/zsh/dr_completion.zsh`
- [x] 1.1.2 Navigate to `_dr_emit_recursive_search()` function (around line 323)
- [x] 1.1.3 Refactored to separate folders and scripts into separate arrays
- [x] 1.1.4 Added `_wanted folders` and `_wanted scripts` for proper tag registration
- [x] 1.1.5 Added `-U` flag to bypass zsh's prefix matching
- [x] 1.1.6 Removed debug logging from this function (6 statements)
- [x] 1.1.7 Added trailing slash to folder matches for proper completion

**Validation:** Core fix in place with `_wanted` for zstyle menu support ✅

---

### 1.2 Test Core Fix

- [x] 1.2.1 Test scripts verified to exist:
  - `folder1/tab-testing`, `folder1/folder2/folder3/tab-testing`
  - `status/bk`, `git/status/bk`
  - `prStats`, `git/status/prStats`
- [x] 1.2.2 User tested completion (reported "works more or less")
- [x] 1.2.3 Fixed 3 critical bugs found by code review:
  - Double trailing slash bug
  - Broken dirname extraction
  - Root folder branch detection
- [x] 1.2.4 Verified hierarchical navigation unchanged
- [x] 1.2.5 Verified namespace commands (`-s`, `-a`, `-c`, `-col`) unchanged

**Validation:** Core fix verified, trailing slash bugs fixed ✅

---

### 1.3 Fix Auto-Completion Instead of Menu

- [x] 1.3.1 Root cause identified: `-M 'r:|[/]=* r:|=*'` matcher in compadd
- [x] 1.3.2 Problem: Matcher tells zsh "sta" matches "status/" AND "git/status/"
- [x] 1.3.3 Result: Zsh auto-completes to common prefix instead of showing menu
- [x] 1.3.4 Solution: Remove matcher entirely, use `-U` flag (already present)
- [x] 1.3.5 Changed line 380: `compadd -M 'r:|[/]=* r:|=*'` → `compadd -U`
- [x] 1.3.6 Changed line 384: `compadd -M 'r:|[/]=* r:|=*'` → `compadd -U`
- [x] 1.3.7 Updated comments to explain why no matcher is needed

**Validation:** Recursive search shows all matches in menu, no auto-completion ✅

**Technical Details:**

- The recursive search (`_dr_search_recursive`) already finds ALL matches explicitly
- We just need to show what we found - no pattern matching needed
- Matcher was causing zsh to think matches were "equivalent" and auto-completing
- Using `-U` (already present) disables all matching - shows exactly what we found

---

### 1.4 Fix Word Deletion Bug

- [x] 1.4.1 Root cause: `compset -P '*'` before `compadd -U` with no matches deletes word
- [x] 1.4.2 Solution: Use `-i "$PREFIX"` flag instead of `compset -P '*'`
- [x] 1.4.3 Updated `_dr_emit_recursive_search` to use `-i "$PREFIX"` with `-U`
- [x] 1.4.4 Verified word preservation when typing `dr status<TAB>` or `dr prStats<TAB>`

**Validation:** Typed word preserved even when no/few matches found ✅

---

### 1.5 Fix Find Command to Match Full Path

- [x] 1.5.1 Problem: `-iname "*${pattern}*"` only matches basename, not full path
- [x] 1.5.2 Solution: Changed to `-ipath "*${pattern}*"` for full path matching
- [x] 1.5.3 Updated both file and directory find commands in `_dr_search_recursive`

**Validation:** `dr sta<TAB>` now finds `git/status/bk` (path contains "sta") ✅

---

### 1.6 Fix ANSI Codes in compadd Display

- [x] 1.6.1 Problem: `compadd -d` doesn't render ANSI escape codes (shows `^[[33m`)
- [x] 1.6.2 Solution: Removed ANSI color codes, kept only emojis (📁, 🚀)
- [x] 1.6.3 Updated `_dr_emit_recursive_search` to use plain emoji display

**Validation:** Completion menu shows emojis correctly without raw escape codes ✅

---

### 1.7 Refactor: Centralize Folder Decorations (SINGLE SOURCE OF TRUTH)

- [x] 1.7.1 Created `_dr_decorate_folders()` helper function (lines 127-174)
- [x] 1.7.2 Supports two modes:
  - `simple`: Shows "📁 basename/" for hierarchical navigation
  - `fullpath`: Shows "parent/📁 child/" for search results
- [x] 1.7.3 Updated 8 locations to use centralized function:
  - `_dr_add_folders` (line 184)
  - `_dr_emit_context` (line 245)
  - `_dr_emit_recursive_search` (line 447) - fullpath mode
  - `_dr_emit_aliases_context` (line 546)
  - `_dr_emit_configs_context` (line 619)
  - Position 4 move/rename (line 835)
  - Position 4 scripts list (line 892)
  - Position 5 scripts move (line 993)
- [x] 1.7.4 Verified no 📁 emoji outside centralized function

**Validation:** All folder decorations use single source of truth ✅

---

### 1.8 Refactor: Centralize ALL Icon Decorations (SINGLE SOURCE OF TRUTH)

- [x] 1.8.1 Added icon constants at top of file (lines 35-43):
  ```zsh
  FOLDER_ICON='📁'
  SCRIPT_ICON='🚀'
  ALIAS_ICON='🎭'
  CONFIG_ICON='⚙'
  ```
- [x] 1.8.2 Updated `_dr_decorate_folders` to use `FOLDER_ICON` constant
- [x] 1.8.3 Created unified `_dr_decorate_files()` function with type parameter:
  - Takes `type` as first arg: `SCRIPTS` | `ALIASES` | `CONFIGS`
  - Supports `simple` and `fullpath` modes
  - Uses appropriate icon constant based on type
- [x] 1.8.4 Updated all script/alias/config decoration call sites to use `_dr_decorate_files`
- [x] 1.8.5 Removed separate `_dr_decorate_scripts`, `_dr_decorate_aliases`, `_dr_decorate_configs` functions
- [x] 1.8.6 Verified no raw emojis outside constants/decorators

**Validation:** All icon decorations use centralized function with type parameter ✅

**Summary of Decorator Functions:**

| Function               | Modes            | Icon Selection        | Usages |
| ---------------------- | ---------------- | --------------------- | ------ |
| `_dr_decorate_folders` | simple, fullpath | `FOLDER_ICON`         | 8      |
| `_dr_decorate_files`   | simple, fullpath | Based on `type` param | 5      |

---

## Phase 2: Refactor - Consolidate Filesystem Functions

### 2.1 Delete Dead Code

- [x] 2.1.1 Delete `_dr_add_scripts` function (lines ~358-373)
  - Helper function that is never called anywhere
  - Comment at line ~335 references it but function unused
- [x] 2.1.2 Delete `_dr_get_all_scripts` function (lines ~376-394)
  - Recursively gets all scripts but never called
  - Superseded by `_dr_search_recursive`
- [x] 2.1.3 Delete orphaned comment referencing `_dr_add_scripts`
- [x] 2.1.4 Verify syntax: `zsh -n dr_completion.zsh`

**Validation:** No dead code functions remain, syntax check passes ✅

---

### 2.2 Create Unified `_dr_global_filesystem_find` Function

Create a single parameterized function to replace all filesystem getters:

- [x] 2.2.1 Define function signature:

  ```zsh
  # _dr_global_filesystem_find <context> <type> <depth> [subcontext] [sortAz] [pattern]
  #
  # Args:
  #   $1 (context):    'scripts' | 'aliases' | 'configs' | 'collections'
  #                    Maps to: $BIN_DIR, $ALIASES_DIR, $CONFIG_DIR, $COLLECTIONS_DIR
  #   $2 (type):       'file' | 'directory' | 'both'
  #   $3 (depth):      'single' | 'all'
  #   $4 (subcontext): Optional relative path within context (e.g., "ai/tools/")
  #   $5 (sortAz):     Optional, default 'true' - alphabetical sort
  #   $6 (pattern):    Optional filter pattern for -ipath matching
  #
  # Returns: One result per line (stdout)
  #   - Directories: "dirname/" (with trailing slash)
  #   - Files: "filename" (extension stripped based on context)
  ```

- [x] 2.2.2 Implement context → base_dir mapping:

  ```zsh
  case "$context" in
    scripts)     base_dir="$BIN_DIR";        ext=".sh" ;;
    aliases)     base_dir="$ALIASES_DIR";    ext=".aliases" ;;
    configs)     base_dir="$CONFIG_DIR";     ext=".config" ;;
    collections) base_dir="$COLLECTIONS_DIR"; ext="" ;;
  esac
  ```

- [x] 2.2.3 Implement type → find options:

  ```zsh
  case "$type" in
    file)      find_type=(-type f) ;;
    directory) find_type=(-type d) ;;
    both)      find_type=() ;;  # No -type filter
  esac
  ```

- [x] 2.2.4 Implement depth → maxdepth:

  ```zsh
  case "$depth" in
    single) find_depth=(-maxdepth 1) ;;
    all)    find_depth=() ;;  # No limit
  esac
  ```

- [x] 2.2.5 Implement pattern filtering (optional):

  ```zsh
  if [[ -n "$pattern" ]]; then
    find_pattern=(-ipath "*${pattern}*")
  fi
  ```

- [x] 2.2.6 Implement output post-processing:
  - Strip base_dir prefix
  - Strip file extension based on context
  - Add trailing `/` for directories
  - Exclude hidden files/folders (`.*`)

- [x] 2.2.7 Add sorting (if sortAz=true):

  ```zsh
  if [[ "$sortAz" == "true" ]]; then
    ... | sort -z | tr '\0' '\n'
  fi
  ```

- [x] 2.2.8 Verify function with test cases:

  ```zsh
  # Test: Get immediate script folders
  _dr_global_filesystem_find scripts directory single

  # Test: Get all scripts recursively
  _dr_global_filesystem_find scripts file all

  # Test: Get alias files in subcontext
  _dr_global_filesystem_find aliases file single "git/"

  # Test: Pattern search
  _dr_global_filesystem_find scripts file all "" true "status"
  ```

**Validation:** Unified function works for all context/type/depth combinations ✅

---

### 2.3 Replace Folder Getter Functions

- [x] 2.3.1 Update all `_dr_get_folders` call sites:

  ```zsh
  # Before: _dr_get_folders "$context"
  # After:  _dr_global_filesystem_find scripts directory single "$context"
  ```

  - Line ~319 in `_dr_emit_context`
  - Line ~878 with `_dr_add_folders`
  - Line ~898 in move/rename destination
  - Line ~955 in `-s list` subcommand
  - Line ~1056 in `-s move/rename` destination

- [x] 2.3.2 Update all `_dr_get_alias_folders` call sites:

  ```zsh
  # Before: _dr_get_alias_folders "$context"
  # After:  _dr_global_filesystem_find aliases directory single "$context"
  ```

  - Line ~612 in `_dr_emit_aliases_context`

- [x] 2.3.3 Update all `_dr_get_config_folders` call sites:

  ```zsh
  # Before: _dr_get_config_folders "$context"
  # After:  _dr_global_filesystem_find configs directory single "$context"
  ```

  - Line ~682 in `_dr_emit_configs_context`

- [x] 2.3.4 Delete old functions:
  - `_dr_get_folders` (lines ~286-308)
  - `_dr_get_alias_folders` (lines ~557-579)
  - `_dr_get_config_folders` (lines ~627-649)

- [x] 2.3.5 Verify syntax: `zsh -n dr_completion.zsh`

**Validation:** All folder getters replaced, old functions deleted ✅

---

### 2.4 Replace File Getter Functions

- [x] 2.4.1 Update all `_dr_get_scripts` call sites:

  ```zsh
  # Before: _dr_get_scripts "$context"
  # After:  _dr_global_filesystem_find scripts file single "$context"
  ```

  - Line ~320 in `_dr_emit_context`

- [x] 2.4.2 Update all `_dr_get_alias_files` call sites:

  ```zsh
  # Before: _dr_get_alias_files "$context"
  # After:  _dr_global_filesystem_find aliases file single "$context"
  ```

  - Line ~613 in `_dr_emit_aliases_context`

- [x] 2.4.3 Update all `_dr_get_config_files` call sites:

  ```zsh
  # Before: _dr_get_config_files "$context"
  # After:  _dr_global_filesystem_find configs file single "$context"
  ```

  - Line ~683 in `_dr_emit_configs_context`

- [x] 2.4.4 Delete old functions:
  - `_dr_get_scripts` (lines ~336-355)
  - `_dr_get_alias_files` (lines ~582-601)
  - `_dr_get_config_files` (lines ~652-671)

- [x] 2.4.5 Verify syntax: `zsh -n dr_completion.zsh`

**Validation:** All file getters replaced, old functions deleted ✅

---

### 2.5 Split Emit Context into Get + Display

#### 2.5.1 Create `_dr_get_feature_context` Function

- [x] 2.5.1.1 Define function signature:

  ```zsh
  # _dr_get_feature_context <feature> <subcontext> [depth] [filter]
  #
  # Args:
  #   $1 (feature):    'scripts' | 'aliases' | 'configs'
  #   $2 (subcontext): Relative path context (e.g., "ai/tools/" or "")
  #   $3 (depth):      'single' | 'all' (default: 'single')
  #   $4 (filter):     Optional pattern filter for matching
  #
  # Output format (stdout, one per line):
  #   TYPE:NAME
  #   - "folder:dirname/"   for directories
  #   - "file:filename"     for files (extension stripped)
  #
  # Example output:
  #   folder:ai/
  #   folder:git/
  #   file:status
  #   file:deploy
  ```

- [x] 2.5.1.2 Implement function:

  ```zsh
  _dr_get_feature_context() {
    local feature="$1" subcontext="$2" depth="${3:-single}" filter="${4:-}"

    # Get folders
    while IFS= read -r folder; do
      [[ -n "$folder" ]] && echo "folder:$folder"
    done < <(_dr_global_filesystem_find "$feature" directory "$depth" "$subcontext" true "$filter")

    # Get files
    while IFS= read -r file; do
      [[ -n "$file" ]] && echo "file:$file"
    done < <(_dr_global_filesystem_find "$feature" file "$depth" "$subcontext" true "$filter")
  }
  ```

- [x] 2.5.1.3 Verify function outputs correctly

#### 2.5.2 Create `_dr_display_feature_context` Function

- [x] 2.5.2.1 Define function signature:

  ```zsh
  # _dr_display_feature_context <feature> <prefix>
  #
  # Reads piped data from _dr_get_feature_context
  # Decorates and displays using compadd with _wanted tags
  #
  # Args:
  #   $1 (feature): 'scripts' | 'aliases' | 'configs' (determines icons)
  #   $2 (prefix):  Prefix to prepend to matches (e.g., "ai/tools/")
  #
  # Input format (stdin):
  #   folder:dirname/
  #   file:filename
  ```

- [x] 2.5.2.2 Implement function:

  ```zsh
  _dr_display_feature_context() {
    local feature="$1" prefix="$2"
    local -a folders files folder_matches folder_displays file_matches file_displays
    local line type name

    # Parse input
    while IFS= read -r line; do
      type="${line%%:*}"
      name="${line#*:}"
      case "$type" in
        folder) folders+=("$name") ;;
        file)   files+=("$name") ;;
      esac
    done

    # Decorate folders
    _dr_decorate_folders folder_matches folder_displays "$prefix" simple "${folders[@]}"

    # Decorate files (using feature to determine icon type)
    local file_type
    case "$feature" in
      scripts) file_type="SCRIPTS" ;;
      aliases) file_type="ALIASES" ;;
      configs) file_type="CONFIGS" ;;
    esac
    _dr_decorate_files "$file_type" file_matches file_displays "$prefix" simple "${files[@]}"

    # Emit with _wanted tags
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
    (( ${#file_matches[@]} )) && _wanted "$feature" expl "$feature" compadd -d file_displays -a -- file_matches
  }
  ```

- [x] 2.5.2.3 Verify decoration and display work correctly

#### 2.5.3 Create Piped Usage Pattern

- [x] 2.5.3.1 Verify piping works:

  ```zsh
  # Usage pattern:
  _dr_get_feature_context scripts "ai/tools/" | _dr_display_feature_context scripts "ai/tools/"

  # With filter:
  _dr_get_feature_context scripts "" "status" | _dr_display_feature_context scripts ""
  ```

**Validation:** Get and display functions work correctly when piped ✅

---

### 2.6 Replace Emit Context Functions

- [x] 2.6.1 Replace `_dr_emit_context` call sites:

  ```zsh
  # Before:
  _dr_emit_context "$context_path" "$context_path"

  # After:
  _dr_get_feature_context scripts "$context_path" | _dr_display_feature_context scripts "$context_path"
  ```

  - All call sites in POSITION 2, 3, 4, 5 sections replaced (19 locations)

- [x] 2.6.2 Replace `_dr_emit_aliases_context` call sites:

  ```zsh
  # Before:
  _dr_emit_aliases_context "$context" "$prefix"

  # After:
  _dr_get_feature_context aliases "$context" | _dr_display_feature_context aliases "$prefix"
  ```

  - Replaced 2 call sites (root context in set/remove subcommands)

- [x] 2.6.3 Replace `_dr_emit_configs_context` call sites:

  ```zsh
  # Before:
  _dr_emit_configs_context "$context" "$prefix"

  # After:
  _dr_get_feature_context configs "$context" | _dr_display_feature_context configs "$prefix"
  ```

  - Replaced 4 call sites (folder + root context in set/edit subcommands)

- [x] 2.6.4 Delete old functions:
  - `_dr_emit_context` - deleted (~22 lines)
  - `_dr_emit_aliases_context` - deleted (~22 lines)
  - `_dr_emit_configs_context` - deleted (~22 lines)

- [x] 2.6.5 Verify syntax: `zsh -n dr_completion.zsh` ✅

**Validation:** All emit functions replaced with get+display combo ✅

---

### 2.7 Lazy-Load Always-Running Sections

The following sections currently run on EVERY `dr <TAB>` even when not needed:

- "# Get config keys (recursive search)" (lines ~696-702)
- "# Get alias categories" (lines ~704-714)
- "# Get config categories" (lines ~716-726)

#### 2.7.1 Create Lazy-Loading Functions

- [ ] 2.7.1.1 Create `_dr_ensure_config_keys_loaded`:

  ```zsh
  # Global state (reset per completion invocation)
  typeset -g _DR_CONFIG_KEYS_LOADED=false
  typeset -ga _DR_CONFIG_KEYS=()

  _dr_ensure_config_keys_loaded() {
    [[ "$_DR_CONFIG_KEYS_LOADED" == "true" ]] && return 0

    _DR_CONFIG_KEYS=()
    if [[ -d "$CONFIG_DIR" ]]; then
      while IFS= read -r config_file; do
        [[ -f "$config_file" ]] && _DR_CONFIG_KEYS+=(${(f)"$(grep -E "^export " "$config_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort)"})
      done < <(find "$CONFIG_DIR" -name "*.config" -type f 2>/dev/null)
    fi
    _DR_CONFIG_KEYS_LOADED=true
  }
  ```

- [ ] 2.7.1.2 Create `_dr_ensure_alias_categories_loaded`:

  ```zsh
  typeset -g _DR_ALIAS_CATEGORIES_LOADED=false
  typeset -ga _DR_ALIAS_CATEGORIES=()

  _dr_ensure_alias_categories_loaded() {
    [[ "$_DR_ALIAS_CATEGORIES_LOADED" == "true" ]] && return 0

    _DR_ALIAS_CATEGORIES=()
    if [[ -d "$ALIASES_DIR" ]]; then
      while IFS= read -r alias_file; do
        if [[ -f "$alias_file" ]]; then
          local rel_path="${alias_file#$ALIASES_DIR/}"
          local category="${rel_path%.aliases}"
          _DR_ALIAS_CATEGORIES+=("$category")
        fi
      done < <(find "$ALIASES_DIR" -name "*.aliases" -type f 2>/dev/null)
    fi
    _DR_ALIAS_CATEGORIES_LOADED=true
  }
  ```

- [ ] 2.7.1.3 Create `_dr_ensure_config_categories_loaded`:

  ```zsh
  typeset -g _DR_CONFIG_CATEGORIES_LOADED=false
  typeset -ga _DR_CONFIG_CATEGORIES=()

  _dr_ensure_config_categories_loaded() {
    [[ "$_DR_CONFIG_CATEGORIES_LOADED" == "true" ]] && return 0

    _DR_CONFIG_CATEGORIES=()
    if [[ -d "$CONFIG_DIR" ]]; then
      while IFS= read -r config_file; do
        if [[ -f "$config_file" ]]; then
          local rel_path="${config_file#$CONFIG_DIR/}"
          local category="${rel_path%.config}"
          _DR_CONFIG_CATEGORIES+=("$category")
        fi
      done < <(find "$CONFIG_DIR" -name "*.config" -type f 2>/dev/null)
    fi
    _DR_CONFIG_CATEGORIES_LOADED=true
  }
  ```

#### 2.7.2 Reset State at Start of `_dr()`

- [ ] 2.7.2.1 Add reset block at start of `_dr()` function:

  ```zsh
  _dr() {
    # Reset lazy-load state for this completion invocation
    _DR_CONFIG_KEYS_LOADED=false
    _DR_ALIAS_CATEGORIES_LOADED=false
    _DR_CONFIG_CATEGORIES_LOADED=false

    # ... rest of function
  }
  ```

#### 2.7.3 Update Usage Sites

- [ ] 2.7.3.1 Replace `config_keys` usage (lines ~1025, ~1075):

  ```zsh
  # Before:
  _describe -t config-keys 'config keys' config_keys

  # After:
  _dr_ensure_config_keys_loaded
  _describe -t config-keys 'config keys' _DR_CONFIG_KEYS
  ```

- [ ] 2.7.3.2 Replace `alias_categories` usage (line ~1067):

  ```zsh
  # Before:
  _describe -t alias-categories 'alias categories' alias_categories

  # After:
  _dr_ensure_alias_categories_loaded
  _describe -t alias-categories 'alias categories' _DR_ALIAS_CATEGORIES
  ```

- [ ] 2.7.3.3 Replace `config_categories` usage (lines ~1081, ~1086):

  ```zsh
  # Before:
  _describe -t config-categories 'config categories' config_categories

  # After:
  _dr_ensure_config_categories_loaded
  _describe -t config-categories 'config categories' _DR_CONFIG_CATEGORIES
  ```

#### 2.7.4 Remove Always-Running Sections

- [ ] 2.7.4.1 Delete the three always-running blocks (lines ~696-726)
- [ ] 2.7.4.2 Verify syntax: `zsh -n dr_completion.zsh`
- [ ] 2.7.4.3 Test that lazy-loading works correctly

**Validation:** Data only loaded when needed, not on every completion ✅

---

### 2.8 Final Phase 2 Verification

- [ ] 2.8.1 Run full syntax check: `zsh -n dr_completion.zsh`
- [ ] 2.8.2 Test hierarchical navigation: `dr <TAB>`, `dr git/<TAB>`
- [ ] 2.8.3 Test recursive search: `dr sta<TAB>`, `dr prSt<TAB>`
- [ ] 2.8.4 Test namespace commands: `dr -s <TAB>`, `dr -a <TAB>`, `dr -c <TAB>`
- [ ] 2.8.5 Test deep navigation: `dr -a aliases set git/<TAB>`
- [ ] 2.8.6 Verify no performance regression (completion should feel fast)

**Validation:** All functionality preserved after refactoring ✅

---

## Phase 3: Remove Debug Logging

### 3.1 Remove Main Function Debug Block

- [ ] 3.1.1 🔀 Find lines 37-44 (main `_dr()` entry debug block)
- [ ] 3.1.2 🔀 Remove the entire block:
  ```zsh
  {
    echo "========================================"
    echo "_dr() called at $(date +%H:%M:%S)"
    echo "CURRENT=$CURRENT"
    echo "words=(${words[@]})"
    echo "========================================"
  } >> /tmp/dr_completion_debug.log
  ```

**Validation:** No debug block at start of `_dr()` function

---

### 3.2 Remove Recursive Search Debug Logging

- [ ] 3.2.1 🔀 Remove line 328:
  ```zsh
  echo ">>> _dr_emit_recursive_search called with pattern='$pattern'" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.2.2 🔀 Remove lines 361-362:
  ```zsh
  echo ">>> Found ${#matches[@]} matches" >> /tmp/dr_completion_debug.log
  printf '>>> Match: %s\n' "${matches[@]}" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.2.3 🔀 Remove line 365:
  ```zsh
  echo ">>> Adding ${#matches[@]} completions..." >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.2.4 🔀 Remove line 373:
  ```zsh
  echo ">>> Done adding completions with compadd" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.2.5 🔀 Remove line 376:
  ```zsh
  echo ">>> NO MATCHES - returning 1" >> /tmp/dr_completion_debug.log
  ```

**Validation:** No debug logging in `_dr_emit_recursive_search()`

---

### 3.3 Remove POSITION 2 Debug Logging

- [ ] 3.3.1 🔀 Remove lines 570-576 (POSITION 2 entry block):
  ```zsh
  {
    echo "----------------------------------------"
    echo "POSITION 2: current_word='$current_word'"
    echo "----------------------------------------"
  } >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.3.2 🔀 Remove line 580:
  ```zsh
  echo "Branch: current_word contains /" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.3.3 🔀 Remove line 591:
  ```zsh
  echo "Branch: current_word is pattern (non-empty, not flag)" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.3.4 🔀 Remove line 596:
  ```zsh
  echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.3.5 🔀 Remove line 599:
  ```zsh
  echo "Branch: empty or flag - showing hints + context" >> /tmp/dr_completion_debug.log
  ```

**Validation:** No debug logging in POSITION 2 section

---

### 3.4 Remove POSITION 3 Debug Logging

- [ ] 3.4.1 🔀 Remove lines 621-629 (POSITION 3 entry block):
  ```zsh
  {
    echo "----------------------------------------"
    echo "POSITION 3: word2='$word2', current_word='$current_word'"
    echo "----------------------------------------"
  } >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.4.2 🔀 Remove line 633:
  ```zsh
  echo "Branch: -s/scripts namespace" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.4.3 🔀 Remove line 641:
  ```zsh
  echo "Branch: scripts namespace pattern search" >> /tmp/dr_completion_debug.log
  ```
- [ ] 3.4.4 🔀 Search for any remaining debug log writes:
  ```bash
  grep -n "dr_completion_debug" core/shared/dotrun/shell/zsh/dr_completion.zsh
  ```
- [ ] 3.4.5 🔀 Remove any remaining instances found

**Validation:** `grep "dr_completion_debug" dr_completion.zsh` returns no results

---

### 3.5 Verify No Debug Log Writes

- [ ] 3.5.1 Remove existing debug log: `rm -f /tmp/dr_completion_debug.log`
- [ ] 3.5.2 Reload zsh: `exec zsh`
- [ ] 3.5.3 Trigger completions: `dr <TAB>`, `dr git/<TAB>`, `dr tab<TAB>`
- [ ] 3.5.4 Verify log file not created: `ls -la /tmp/dr_completion_debug.log`
- [ ] 3.5.5 File should not exist

**Validation:** `/tmp/dr_completion_debug.log` does not exist after completion operations

---

## Phase 4: Fix Shellcheck and Return Values

### 4.1 Fix Shellcheck Declaration

- [ ] 4.1.1 Open `core/shared/dotrun/shell/zsh/dr_completion.zsh`
- [ ] 4.1.2 Find line 2:
  ```bash
  # shellcheck shell=bash disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
  ```
- [ ] 4.1.3 Change `shell=bash` to `shell=zsh`:
  ```bash
  # shellcheck shell=zsh disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
  ```

**Validation:** Shellcheck directive declares correct shell type

---

### 4.2 Fix Return Value at Line 597

- [ ] 4.2.1 Find the recursive search call around line 594-597:
  ```zsh
  if [[ -n "$current_word" && "$current_word" != -* ]]; then
    _dr_emit_recursive_search "$current_word"
    # Return immediately - no other completions allowed
    echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
    return
  ```
- [ ] 4.2.2 Replace with (after debug log removal):
  ```zsh
  if [[ -n "$current_word" && "$current_word" != -* ]]; then
    _dr_emit_recursive_search "$current_word" && return 0 || return 1
  ```
- [ ] 4.2.3 Remove any leftover comments about debug logging

**Validation:** Return value from `_dr_emit_recursive_search` is properly propagated

---

## Phase 5: Comprehensive Testing

### 5.1 Test Recursive Search Scenarios

- [ ] 5.1.1 Create additional test scripts:
  ```bash
  dr set prStats
  dr set git/status/prStats
  dr set git/prs/prReady
  ```
- [ ] 5.1.2 Test prefix matching: `dr pr<TAB>`
  - Should show: `prStats`, `git/status/prStats`, `git/prs/prReady`
- [ ] 5.1.3 Test substring matching: `dr Stat<TAB>`
  - Should show: `prStats`, `git/status/prStats` (if substring matching enabled)
- [ ] 5.1.4 Test no matches: `dr nonexistent<TAB>`
  - Should show nothing
- [ ] 5.1.5 Verify emoji display: 🚀 for scripts, 📁 for folders

**Validation:** All recursive search scenarios work correctly

---

### 5.2 Test Hierarchical Navigation Unchanged

- [ ] 5.2.1 Test empty root: `dr <TAB>`
  - Should show folders, scripts, hint message
- [ ] 5.2.2 Test folder navigation: `dr folder1/<TAB>`
  - Should show `folder2/`, `tab-testing`
- [ ] 5.2.3 Test deep navigation: `dr folder1/folder2/<TAB>`
  - Should show `folder3/`
- [ ] 5.2.4 Test namespace: `dr -s <TAB>`
  - Should show `set`, `edit`, `help`, `move`, `remove` + recursive search

**Validation:** Hierarchical navigation and namespace commands unchanged

---

### 5.3 Test Edge Cases

- [ ] 5.3.1 Test with spaces in folder names (if applicable)
- [ ] 5.3.2 Test with special characters in script names
- [ ] 5.3.3 Test with very deep nesting (5+ levels)
- [ ] 5.3.4 Test with large number of scripts (50+)
- [ ] 5.3.5 Test completion performance (should be fast)

**Validation:** Edge cases handled correctly

---

## Phase 6: Cleanup and Documentation

### 6.1 Clean Up Test Scripts

- [ ] 6.1.1 Remove test scripts created during testing:
  ```bash
  dr remove folder1/tab-testing
  dr remove folder1/folder2/folder3/tab-testing
  dr remove prStats
  dr remove git/status/prStats
  dr remove git/prs/prReady
  ```
- [ ] 6.1.2 Verify scripts removed: `dr -l`

**Validation:** Test environment cleaned up

---

### 6.2 Update Line Numbers in Comments (if applicable)

- [ ] 6.2.1 Review any comments referencing specific line numbers
- [ ] 6.2.2 Update line numbers if they changed due to debug removal
- [ ] 6.2.3 Ensure comments are accurate

**Validation:** Comments reference correct line numbers

---

### 6.3 Final Code Review

- [ ] 6.3.1 Read through modified `_dr_emit_recursive_search()` function
- [ ] 6.3.2 Read through POSITION 2 section
- [ ] 6.3.3 Verify no leftover debug code or comments
- [ ] 6.3.4 Verify consistent code style

**Validation:** Code is clean and well-structured

---

## Phase 7: Validation and Archive

### 7.1 OpenSpec Validation

- [ ] 7.1.1 Run: `openspec validate fix-zsh-recursive-completion --strict`
- [ ] 7.1.2 Fix any validation errors
- [ ] 7.1.3 Re-run validation until passing

**Validation:** `openspec validate --strict` passes

---

### 7.2 Final Acceptance Testing

- [ ] 7.2.1 Verify: `dr <partial-name><TAB>` shows all matching scripts
- [ ] 7.2.2 Verify: Results display with emojis and colors
- [ ] 7.2.3 Verify: Results sorted by priority then depth
- [ ] 7.2.4 Verify: No debug output in normal usage
- [ ] 7.2.5 Verify: Shellcheck passes with `shell=zsh`

**Validation:** All acceptance criteria met

---

### 7.3 Archive OpenSpec Change (after approval)

- [ ] 7.3.1 Run: `openspec archive fix-zsh-recursive-completion`
- [ ] 7.3.2 Verify change archived successfully
- [ ] 7.3.3 Update specs if needed: move shell-completion spec to `openspec/specs/`

**Validation:** OpenSpec change archived

---

## Summary Statistics

**Total Tasks:** 65+ tasks across 7 phases

**Phase Overview:**

| Phase | Name                             | Status      | Tasks   |
| ----- | -------------------------------- | ----------- | ------- |
| 1     | Core Bug Fix                     | ✅ COMPLETE | 1.1-1.8 |
| 2     | Refactor Filesystem Functions    | 🔲 PENDING  | 2.1-2.8 |
| 3     | Remove Debug Logging             | 🔲 PENDING  | 3.1-3.5 |
| 4     | Fix Shellcheck and Return Values | 🔲 PENDING  | 4.1-4.2 |
| 5     | Comprehensive Testing            | 🔲 PENDING  | 5.1-5.3 |
| 6     | Cleanup and Documentation        | 🔲 PENDING  | 6.1-6.3 |
| 7     | Validation and Archive           | 🔲 PENDING  | 7.1-7.3 |

**Critical Path:**

- Phase 1 (1.1 → 1.8): Core fix and refactoring ✅
- Phase 2 (2.1 → 2.8): Filesystem function consolidation
- Phase 3 (3.1-3.5): Debug removal
- Phase 4 (4.1-4.2): Shellcheck and return values
- Phase 5 (5.1-5.3): Comprehensive testing

**Parallelizable:**

- All 3.x tasks can run in parallel
- Testing tasks (5.x) can partially overlap

**Dependencies:**

- Phase 2 depends on Phase 1 completion
- Phase 3-4 depend on Phase 2 completion
- Phase 5 depends on Phase 3-4 completion
- Phase 6-7 depend on Phase 5 completion

**Functions to Delete (Phase 2):**

- `_dr_add_scripts` (dead code)
- `_dr_get_all_scripts` (dead code)
- `_dr_get_folders` (replaced by `_dr_global_filesystem_find`)
- `_dr_get_scripts` (replaced by `_dr_global_filesystem_find`)
- `_dr_get_alias_folders` (replaced by `_dr_global_filesystem_find`)
- `_dr_get_alias_files` (replaced by `_dr_global_filesystem_find`)
- `_dr_get_config_folders` (replaced by `_dr_global_filesystem_find`)
- `_dr_get_config_files` (replaced by `_dr_global_filesystem_find`)
- `_dr_emit_context` (replaced by get+display combo)
- `_dr_emit_aliases_context` (replaced by get+display combo)
- `_dr_emit_configs_context` (replaced by get+display combo)

**New Functions (Phase 2):**

- `_dr_global_filesystem_find` (unified filesystem search)
- `_dr_get_feature_context` (data retrieval)
- `_dr_display_feature_context` (decoration + display)
- `_dr_ensure_config_keys_loaded` (lazy loader)
- `_dr_ensure_alias_categories_loaded` (lazy loader)
- `_dr_ensure_config_categories_loaded` (lazy loader)

**Progress Tracking:**

- Mark tasks with ✅ as completed
- File: `core/shared/dotrun/shell/zsh/dr_completion.zsh`
