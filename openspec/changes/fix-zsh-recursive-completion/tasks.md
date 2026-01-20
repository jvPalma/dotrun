# Fix ZSH Recursive Completion - Task List

## Task Organization

Tasks are organized into phases. Each task is designed to be small, verifiable, and deliver visible progress.

**Parallelizable tasks** are marked with 🔀
**Critical path tasks** have dependencies noted

---

## Phase 1: Core Bug Fix

### 1.1 Add `-U` Flag to Recursive Search Emit

- [ ] 1.1.1 Open `core/shared/dotrun/shell/zsh/dr_completion.zsh`
- [ ] 1.1.2 Navigate to `_dr_emit_recursive_search()` function (around line 323)
- [ ] 1.1.3 Find the `compadd` call at line 371:
  ```zsh
  compadd -M 'r:|[/]=* r:|=*' -d displays -a -- matches
  ```
- [ ] 1.1.4 Add `-U` flag to bypass zsh's prefix matching:
  ```zsh
  compadd -U -M 'r:|[/]=* r:|=*' -d displays -a -- matches
  ```
- [ ] 1.1.5 Save file

**Validation:** Core fix in place, ready for testing

---

### 1.2 Test Core Fix

- [ ] 1.2.1 Create test scripts:
  ```bash
  dr set folder1/folder2/folder3/tab-testing
  dr set folder1/tab-testing
  ```
- [ ] 1.2.2 Reload zsh completion: `exec zsh`
- [ ] 1.2.3 Test `dr tab-t<TAB>` shows both matches
- [ ] 1.2.4 Test `dr tab-testing<TAB>` shows both matches
- [ ] 1.2.5 Verify paths displayed correctly with emojis

**Validation:** `dr tab-t<TAB>` shows `folder1/tab-testing` and `folder1/folder2/folder3/tab-testing`

---

## Phase 2: Remove Debug Logging

### 2.1 Remove Main Function Debug Block

- [ ] 2.1.1 🔀 Find lines 37-44 (main `_dr()` entry debug block)
- [ ] 2.1.2 🔀 Remove the entire block:
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

### 2.2 Remove Recursive Search Debug Logging

- [ ] 2.2.1 🔀 Remove line 328:
  ```zsh
  echo ">>> _dr_emit_recursive_search called with pattern='$pattern'" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.2.2 🔀 Remove lines 361-362:
  ```zsh
  echo ">>> Found ${#matches[@]} matches" >> /tmp/dr_completion_debug.log
  printf '>>> Match: %s\n' "${matches[@]}" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.2.3 🔀 Remove line 365:
  ```zsh
  echo ">>> Adding ${#matches[@]} completions..." >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.2.4 🔀 Remove line 373:
  ```zsh
  echo ">>> Done adding completions with compadd" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.2.5 🔀 Remove line 376:
  ```zsh
  echo ">>> NO MATCHES - returning 1" >> /tmp/dr_completion_debug.log
  ```

**Validation:** No debug logging in `_dr_emit_recursive_search()`

---

### 2.3 Remove POSITION 2 Debug Logging

- [ ] 2.3.1 🔀 Remove lines 570-576 (POSITION 2 entry block):
  ```zsh
  {
    echo "----------------------------------------"
    echo "POSITION 2: current_word='$current_word'"
    echo "----------------------------------------"
  } >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.3.2 🔀 Remove line 580:
  ```zsh
  echo "Branch: current_word contains /" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.3.3 🔀 Remove line 591:
  ```zsh
  echo "Branch: current_word is pattern (non-empty, not flag)" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.3.4 🔀 Remove line 596:
  ```zsh
  echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.3.5 🔀 Remove line 599:
  ```zsh
  echo "Branch: empty or flag - showing hints + context" >> /tmp/dr_completion_debug.log
  ```

**Validation:** No debug logging in POSITION 2 section

---

### 2.4 Remove POSITION 3 Debug Logging

- [ ] 2.4.1 🔀 Remove lines 621-629 (POSITION 3 entry block):
  ```zsh
  {
    echo "----------------------------------------"
    echo "POSITION 3: word2='$word2', current_word='$current_word'"
    echo "----------------------------------------"
  } >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.4.2 🔀 Remove line 633:
  ```zsh
  echo "Branch: -s/scripts namespace" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.4.3 🔀 Remove line 641:
  ```zsh
  echo "Branch: scripts namespace pattern search" >> /tmp/dr_completion_debug.log
  ```
- [ ] 2.4.4 🔀 Search for any remaining debug log writes:
  ```bash
  grep -n "dr_completion_debug" core/shared/dotrun/shell/zsh/dr_completion.zsh
  ```
- [ ] 2.4.5 🔀 Remove any remaining instances found

**Validation:** `grep "dr_completion_debug" dr_completion.zsh` returns no results

---

### 2.5 Verify No Debug Log Writes

- [ ] 2.5.1 Remove existing debug log: `rm -f /tmp/dr_completion_debug.log`
- [ ] 2.5.2 Reload zsh: `exec zsh`
- [ ] 2.5.3 Trigger completions: `dr <TAB>`, `dr git/<TAB>`, `dr tab<TAB>`
- [ ] 2.5.4 Verify log file not created: `ls -la /tmp/dr_completion_debug.log`
- [ ] 2.5.5 File should not exist

**Validation:** `/tmp/dr_completion_debug.log` does not exist after completion operations

---

## Phase 3: Fix Shellcheck and Return Values

### 3.1 Fix Shellcheck Declaration

- [ ] 3.1.1 Open `core/shared/dotrun/shell/zsh/dr_completion.zsh`
- [ ] 3.1.2 Find line 2:
  ```bash
  # shellcheck shell=bash disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
  ```
- [ ] 3.1.3 Change `shell=bash` to `shell=zsh`:
  ```bash
  # shellcheck shell=zsh disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296
  ```

**Validation:** Shellcheck directive declares correct shell type

---

### 3.2 Fix Return Value at Line 597

- [ ] 3.2.1 Find the recursive search call around line 594-597:
  ```zsh
  if [[ -n "$current_word" && "$current_word" != -* ]]; then
    _dr_emit_recursive_search "$current_word"
    # Return immediately - no other completions allowed
    echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
    return
  ```
- [ ] 3.2.2 Replace with (after debug log removal):
  ```zsh
  if [[ -n "$current_word" && "$current_word" != -* ]]; then
    _dr_emit_recursive_search "$current_word" && return 0 || return 1
  ```
- [ ] 3.2.3 Remove any leftover comments about debug logging

**Validation:** Return value from `_dr_emit_recursive_search` is properly propagated

---

## Phase 4: Comprehensive Testing

### 4.1 Test Recursive Search Scenarios

- [ ] 4.1.1 Create additional test scripts:
  ```bash
  dr set prStats
  dr set git/status/prStats
  dr set git/prs/prReady
  ```
- [ ] 4.1.2 Test prefix matching: `dr pr<TAB>`
  - Should show: `prStats`, `git/status/prStats`, `git/prs/prReady`
- [ ] 4.1.3 Test substring matching: `dr Stat<TAB>`
  - Should show: `prStats`, `git/status/prStats` (if substring matching enabled)
- [ ] 4.1.4 Test no matches: `dr nonexistent<TAB>`
  - Should show nothing
- [ ] 4.1.5 Verify emoji display: 🚀 for scripts, 📁 for folders

**Validation:** All recursive search scenarios work correctly

---

### 4.2 Test Hierarchical Navigation Unchanged

- [ ] 4.2.1 Test empty root: `dr <TAB>`
  - Should show folders, scripts, hint message
- [ ] 4.2.2 Test folder navigation: `dr folder1/<TAB>`
  - Should show `folder2/`, `tab-testing`
- [ ] 4.2.3 Test deep navigation: `dr folder1/folder2/<TAB>`
  - Should show `folder3/`
- [ ] 4.2.4 Test namespace: `dr -s <TAB>`
  - Should show `set`, `edit`, `help`, `move`, `remove` + recursive search

**Validation:** Hierarchical navigation and namespace commands unchanged

---

### 4.3 Test Edge Cases

- [ ] 4.3.1 Test with spaces in folder names (if applicable)
- [ ] 4.3.2 Test with special characters in script names
- [ ] 4.3.3 Test with very deep nesting (5+ levels)
- [ ] 4.3.4 Test with large number of scripts (50+)
- [ ] 4.3.5 Test completion performance (should be fast)

**Validation:** Edge cases handled correctly

---

## Phase 5: Cleanup and Documentation

### 5.1 Clean Up Test Scripts

- [ ] 5.1.1 Remove test scripts created during testing:
  ```bash
  dr remove folder1/tab-testing
  dr remove folder1/folder2/folder3/tab-testing
  dr remove prStats
  dr remove git/status/prStats
  dr remove git/prs/prReady
  ```
- [ ] 5.1.2 Verify scripts removed: `dr -l`

**Validation:** Test environment cleaned up

---

### 5.2 Update Line Numbers in Comments (if applicable)

- [ ] 5.2.1 Review any comments referencing specific line numbers
- [ ] 5.2.2 Update line numbers if they changed due to debug removal
- [ ] 5.2.3 Ensure comments are accurate

**Validation:** Comments reference correct line numbers

---

### 5.3 Final Code Review

- [ ] 5.3.1 Read through modified `_dr_emit_recursive_search()` function
- [ ] 5.3.2 Read through POSITION 2 section
- [ ] 5.3.3 Verify no leftover debug code or comments
- [ ] 5.3.4 Verify consistent code style

**Validation:** Code is clean and well-structured

---

## Phase 6: Validation and Archive

### 6.1 OpenSpec Validation

- [ ] 6.1.1 Run: `openspec validate fix-zsh-recursive-completion --strict`
- [ ] 6.1.2 Fix any validation errors
- [ ] 6.1.3 Re-run validation until passing

**Validation:** `openspec validate --strict` passes

---

### 6.2 Final Acceptance Testing

- [ ] 6.2.1 Verify: `dr <partial-name><TAB>` shows all matching scripts
- [ ] 6.2.2 Verify: Results display with emojis and colors
- [ ] 6.2.3 Verify: Results sorted by priority then depth
- [ ] 6.2.4 Verify: No debug output in normal usage
- [ ] 6.2.5 Verify: Shellcheck passes with `shell=zsh`

**Validation:** All acceptance criteria met

---

### 6.3 Archive OpenSpec Change (after approval)

- [ ] 6.3.1 Run: `openspec archive fix-zsh-recursive-completion`
- [ ] 6.3.2 Verify change archived successfully
- [ ] 6.3.3 Update specs if needed: move shell-completion spec to `openspec/specs/`

**Validation:** OpenSpec change archived

---

## Summary Statistics

**Total Tasks:** 45 tasks across 6 phases

**Critical Path:**

- Phase 1 (1.1 → 1.2): Core fix and testing
- Phase 2 (2.1-2.5): Debug removal
- Phase 3 (3.1-3.2): Shellcheck and return values
- Phase 4 (4.1-4.3): Comprehensive testing

**Parallelizable:**

- All 2.x tasks can run in parallel
- Testing tasks (4.x) can partially overlap

**Dependencies:**

- Phase 2-3 depend on Phase 1 completion
- Phase 4 depends on Phase 2-3 completion
- Phase 5-6 depend on Phase 4 completion

**Progress Tracking:**

- Mark tasks with ✅ as completed
- File: `core/shared/dotrun/shell/zsh/dr_completion.zsh`
