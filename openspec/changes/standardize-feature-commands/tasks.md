# Tasks: Standardize Feature Commands

**IMMUTABLE REQUIREMENTS REFERENCE**: `/home/user/dotrun/featuresCommandOverview.md`

This document outlines all implementation tasks for standardizing command interfaces across Scripts, Aliases, and Configs features in dotrun.

---

## Phase 1: Scripts Namespace Cleanup

**Objective**: Remove deprecated commands and implement `rm` command in scripts namespace

**Validation Criteria**:

- No references to `edit`, `init`, `rename`, `reload`, or `sync` in scripts code or completion
- `dr rm` and `dr -s rm` fully functional with TAB completion
- All commands in summary table (rows 1-7) working correctly

### Tasks

- [ ] **1.1** Remove `edit` command handler from scripts namespace in `/core/shared/dotrun/dr`
  - Search for edit command logic in scripts section
  - Remove all conditional branches handling `edit`
  - Verify no orphaned edit-related code remains

- [ ] **1.2** Remove `edit` from completion arrays
  - Locate `script_commands` array in completion logic
  - Remove `edit` entry
  - Update any completion hints that reference `edit`

- [ ] **1.3** Remove `init` references from scripts namespace
  - Search for any `init` command handlers
  - Remove from scripts section (scripts don't support init)
  - Ensure configs/aliases keep their init if present

- [ ] **1.4** Remove `rename` alias (keep only `move`)
  - Find `rename` command handler
  - Remove or redirect to error message suggesting `move`
  - Update any documentation strings

- [ ] **1.5** Remove `rename` from completion arrays
  - Locate completion definitions
  - Remove `rename` from `script_commands`
  - Update TAB hints

- [ ] **1.6** Remove `reload` from scripts namespace
  - Find scripts-specific reload logic
  - Remove command handler
  - Note: global `dr reload` will be added in Phase 4

- [ ] **1.7** Remove `sync` from scripts namespace
  - Search for `sync` command references
  - Remove all sync-related code
  - Clean up any sync-related helper functions

- [ ] **1.8** Rename `remove` command to `rm` in scripts
  - Find existing `remove` command handler
  - Rename function/case to `rm`
  - Update internal variable names

- [ ] **1.9** Implement `dr rm` and `dr -s rm` commands
  - Ensure `rm` deletes specified script file
  - Add confirmation prompt with color output
  - Show clear success/failure messages
  - Handle both `dr rm` and `dr -s rm` identically

- [ ] **1.10** Add `rm` to completion arrays
  - Add `rm` to `script_commands` array
  - Implement TAB completion showing available scripts
  - Ensure `-s rm TAB` works identically to `rm TAB`

- [ ] **1.11** Update scripts help text
  - Update main help output for scripts
  - Update `-s` help message
  - Ensure all valid commands listed: run (default), set, move, rm, help, -l, -L
  - Remove references to deprecated commands

- [ ] **1.12** Test scripts namespace
  - Test `dr scriptname` (default run)
  - Test `dr set scriptname`
  - Test `dr move scriptname`
  - Test `dr rm scriptname` with confirmation
  - Test `dr help scriptname`
  - Test `dr -l` and `dr -L`
  - Test all with `-s` flag variant
  - Verify TAB completion for each

**Phase 1 Completion Criteria**:

- ✅ Commands `edit`, `init`, `rename`, `reload`, `sync` completely removed
- ✅ Command `rm` fully implemented and tested
- ✅ All `-s` variants mirror default behavior
- ✅ TAB completion working for all valid commands
- ✅ Help text accurate and complete

---

## Phase 2: Aliases Namespace Enhancement

**Objective**: Make default action ADD/EDIT (remove need for `set`), add `-l`/`-L` list commands, rename `remove` to `rm`, add `move` and `help`

**Validation Criteria**:

- `dr -a aliasname` opens editor (no `set` needed)
- `-l` and `-L` list commands functional with tree output
- All commands from summary table (rows 1-7) implemented
- TAB completion matches Scripts implementation style

### Tasks

- [ ] **2.1** Make default action open/edit alias file
  - Modify aliases handler to treat bare `dr -a aliasname` as edit
  - Remove requirement for explicit `set` command
  - Ensure backwards compatibility during transition

- [ ] **2.2** Remove `edit` references from aliases
  - Search for `edit` command in aliases section
  - Remove handlers and completion entries
  - Update help text

- [ ] **2.3** Rename `remove` to `rm` in aliases
  - Update command handler from `remove` to `rm`
  - Update internal function names
  - Maintain confirmation prompt behavior

- [ ] **2.4** Add `move` command to aliases
  - Implement move/rename functionality for alias files
  - Show preview with colors (original path → new path)
  - Add confirmation prompt [Y/y/enter]
  - Fix bug: ensure target path with trailing `/` preserves filename
  - Show success message with colors
  - Implement for both `dr -a move` and `dr aliases move`

- [ ] **2.5** Add `help` command to aliases
  - Implement help command to show alias documentation
  - Extract and display comment block from alias file
  - Handle both `dr -a help` and `dr aliases help`

- [ ] **2.6** Add `-l` list command to aliases
  - Implement `dr -a -l [optional FOLDER/]`
  - Use tree colored view, short format
  - Show folders + alias file names
  - Match Scripts implementation style with aliases colors/icons

- [ ] **2.7** Add `-L` detailed list command to aliases
  - Implement `dr -a -L [optional FOLDER/]`
  - Use tree colored view, long format
  - Show folders + file names + one-liner description from file
  - Match Scripts implementation style

- [ ] **2.8** Update `aliases_commands` completion array
  - Add: `move`, `rm`, `help`, `-l`, `-L`
  - Remove: `edit`, `set`, `rename`, `reload`, `sync`
  - Keep: `init` (aliases support init)

- [ ] **2.9** Update aliases help text
  - Update `dr -a --help` output
  - Update `dr aliases --help` output
  - List valid commands: default (edit), move, rm, help, init, -l, -L
  - Add usage examples

- [ ] **2.10** Test aliases namespace
  - Test `dr -a aliasname` (default edit)
  - Test `dr -a move source target` with preview
  - Test `dr -a rm aliasname` with confirmation
  - Test `dr -a help aliasname`
  - Test `dr -a -l` and `dr -a -L`
  - Test `dr -a init`
  - Test all with `dr aliases` variant
  - Verify TAB completion matches Scripts style

**Phase 2 Completion Criteria**:

- ✅ Default action is edit (no `set` required)
- ✅ Commands `move`, `rm`, `help`, `-l`, `-L` implemented
- ✅ Move command shows colored preview and handles paths correctly
- ✅ TAB completion matches Scripts implementation
- ✅ Help text accurate and complete

---

## Phase 3: Configs Namespace Enhancement

**Objective**: Mirror aliases changes - default edit action, add `-l`/`-L`, rename `remove` to `rm`, add `move` and `help`

**Validation Criteria**:

- `dr -c configname` opens editor (no `set` needed)
- `-l` and `-L` list commands functional with tree output
- All commands from summary table (rows 1-7) implemented
- TAB completion matches Scripts/Aliases implementation style

### Tasks

- [ ] **3.1** Make default action open/edit config file
  - Modify configs handler to treat bare `dr -c configname` as edit
  - Remove requirement for explicit `set` command
  - Ensure backwards compatibility

- [ ] **3.2** Remove `edit` references from configs
  - Search for `edit` command in configs section
  - Remove handlers and completion entries
  - Update help text

- [ ] **3.3** Rename `remove` to `rm` in configs
  - Update command handler from `remove` to `rm`
  - Update internal function names
  - Maintain confirmation prompt behavior

- [ ] **3.4** Add `move` command to configs
  - Implement move/rename functionality for config files
  - Show preview with colors (original path → new path)
  - Add confirmation prompt [Y/y/enter]
  - Fix bug: ensure target path with trailing `/` preserves filename
  - Show success message with colors
  - Implement for both `dr -c move` and `dr config move`

- [ ] **3.5** Add `help` command to configs
  - Implement help command to show config documentation
  - Extract and display comment block from config file
  - Handle both `dr -c help` and `dr config help`

- [ ] **3.6** Add `-l` list command to configs
  - Implement `dr -c -l [optional FOLDER/]`
  - Use tree colored view, short format
  - Show folders + config file names
  - Match Scripts/Aliases implementation style with configs colors/icons

- [ ] **3.7** Add `-L` detailed list command to configs
  - Implement `dr -c -L [optional FOLDER/]`
  - Use tree colored view, long format
  - Show folders + file names + one-liner description from file
  - Match Scripts/Aliases implementation style

- [ ] **3.8** Update `config_commands` completion array
  - Add: `move`, `rm`, `help`, `-l`, `-L`
  - Remove: `edit`, `set`, `rename`, `reload`, `sync`
  - Keep: `init` (configs support init)

- [ ] **3.9** Update configs help text
  - Update `dr -c --help` output
  - Update `dr config --help` output
  - List valid commands: default (edit), move, rm, help, init, -l, -L
  - Add usage examples

- [ ] **3.10** Test configs namespace
  - Test `dr -c configname` (default edit)
  - Test `dr -c move source target` with preview
  - Test `dr -c rm configname` with confirmation
  - Test `dr -c help configname`
  - Test `dr -c -l` and `dr -c -L`
  - Test `dr -c init`
  - Test all with `dr config` variant
  - Verify TAB completion matches Scripts/Aliases style

**Phase 3 Completion Criteria**:

- ✅ Default action is edit (no `set` required)
- ✅ Commands `move`, `rm`, `help`, `-l`, `-L` implemented
- ✅ Move command shows colored preview and handles paths correctly
- ✅ TAB completion matches Scripts/Aliases implementation
- ✅ Help text accurate and complete

---

## Phase 4: Global Reload Command

**Objective**: Add feature-agnostic `dr reload` command that sources ~/.drrc

**Validation Criteria**:

- `dr reload` successfully sources ~/.drrc
- No namespace-specific reload commands remain
- Help text documents reload command

### Tasks

- [ ] **4.1** Implement `dr reload` command
  - Add top-level reload handler (not in any feature namespace)
  - Execute `source ~/.drrc` or equivalent
  - Show success message with color
  - Handle errors gracefully if .drrc not found

- [ ] **4.2** Remove namespace-specific reload commands
  - Verify no `dr -s reload`, `dr -a reload`, `dr -c reload`
  - Remove any remaining reload handlers in feature namespaces
  - Already done in Phases 1-3, verify completeness

- [ ] **4.3** Update main help text
  - Add `reload` to main `dr --help` output
  - Describe as "Reload dotrun by sourcing ~/.drrc"
  - Position appropriately in help structure

- [ ] **4.4** Test global reload
  - Test `dr reload` sources configuration
  - Test reload after making .drrc changes
  - Verify changes take effect immediately
  - Test error handling if .drrc missing

**Phase 4 Completion Criteria**:

- ✅ `dr reload` command functional
- ✅ Sources ~/.drrc successfully
- ✅ No feature-specific reload commands exist
- ✅ Help text updated

---

## Phase 5: TAB Completion Unification

**Objective**: Ensure TAB completion is consistent across all features and all command variants

**Validation Criteria**:

- TAB completion works identically for `dr command` and `dr -flag command`
- Hints are consistent and helpful
- All valid commands appear in completion
- Deprecated commands do not appear

### Tasks

- [ ] **5.1** Update `script_commands` array
  - Final array: `set`, `move`, `rm`, `help`
  - Do NOT include: `edit`, `init`, `rename`, `reload`, `sync`
  - Verify array used by both `dr` and `dr -s` completion

- [ ] **5.2** Update `aliases_commands` array
  - Final array: `move`, `rm`, `help`, `init`, `-l`, `-L`
  - Do NOT include: `edit`, `set`, `rename`, `reload`, `sync`
  - Note: `set` removed because default is edit
  - Verify array used by both `dr -a` and `dr aliases` completion

- [ ] **5.3** Update `config_commands` array
  - Final array: `move`, `rm`, `help`, `init`, `-l`, `-L`
  - Do NOT include: `edit`, `set`, `rename`, `reload`, `sync`
  - Note: `set` removed because default is edit
  - Verify array used by both `dr -c` and `dr config` completion

- [ ] **5.4** Update hint messages for ST1 scenario
  - `dr TAB` should show hint for Scripts commands
  - OLD: showed hints for other features
  - NEW: "Available commands: set, move, rm, help, -l, -L | or specify script name"
  - Ensure `dr -s TAB` shows identical hint

- [ ] **5.5** Ensure `-s`, `-a`, `-c` variants match non-flag behavior
  - `dr -s TAB` = `dr TAB`
  - `dr -s set TAB` = `dr set TAB`
  - `dr -s move TAB` = `dr move TAB`
  - `dr -s rm TAB` = `dr rm TAB`
  - `dr -s help TAB` = `dr help TAB`
  - Same for `-a` and `-c`

- [ ] **5.6** Test all TAB completion scenarios
  - **ST1**: `dr TAB` shows scripts hint + folders + scripts
  - **ST2**: `dr set TAB` shows folders + scripts
  - **ST3**: `dr edit TAB` does not work (removed)
  - **ST4**: `dr init TAB` does not work (removed)
  - **ST5**: `dr rename TAB` does not work (removed)
  - **ST6**: `dr move TAB` shows folders + scripts with proper autocomplete
  - **ST7**: `dr help TAB` shows folders + scripts
  - **ST8**: `dr rm TAB` shows folders + scripts
  - **ST9**: `dr reload TAB` (global, no namespace)
  - **ST10**: `dr sync TAB` does not work (removed)
  - Repeat all with `-s`, `-a`, `-c` flags

**Phase 5 Completion Criteria**:

- ✅ All completion arrays updated and accurate
- ✅ Hints are helpful and correct
- ✅ Flag variants match non-flag behavior exactly
- ✅ All deprecated commands produce no completion
- ✅ All valid commands produce correct completion

---

## Phase 6: Documentation Update

**Objective**: Update all help text outputs to match implementation

**Validation Criteria**:

- `dr --help` shows all valid commands
- `dr -s --help`, `dr -a --help`, `dr -c --help` accurate
- No references to deprecated commands in any help output
- Usage examples are correct

### Tasks

- [ ] **6.1** Update main `dr --help` output
  - Add global `reload` command
  - Update scripts section: run (default), set, move, rm, help, -l, -L
  - Update aliases section: edit (default), move, rm, help, init, -l, -L
  - Update configs section: edit (default), move, rm, help, init, -l, -L
  - Remove all references to: edit, init (scripts), rename, reload (namespaced), sync

- [ ] **6.2** Update `dr -s --help` (scripts help)
  - Commands: run (default), set, move, rm, help
  - Flags: -l, -L
  - Add usage examples
  - Remove deprecated commands

- [ ] **6.3** Update `dr -a --help` (aliases help)
  - Commands: edit (default), move, rm, help, init
  - Flags: -l, -L
  - Add usage examples
  - Remove deprecated commands
  - Note: `set` no longer needed

- [ ] **6.4** Update `dr -c --help` (configs help)
  - Commands: edit (default), move, rm, help, init
  - Flags: -l, -L
  - Add usage examples
  - Remove deprecated commands
  - Note: `set` no longer needed

- [ ] **6.5** Verify help matches implementation
  - Cross-reference each help command with actual implementation
  - Test each example from help text
  - Ensure no outdated information

**Phase 6 Completion Criteria**:

- ✅ All help outputs updated
- ✅ No deprecated commands mentioned
- ✅ Usage examples work as documented
- ✅ Help text matches actual behavior

---

## Phase 7: Validation and Archive

**Objective**: Final end-to-end validation against requirements document, comprehensive testing, and archive

**Validation Criteria**:

- All requirements in `featuresCommandOverview.md` met
- All summary table rows (Scripts 1-7, Aliases 1-7, Configs 1-7) marked 🟢
- All test scenarios pass
- Ready for production

### Tasks

- [ ] **7.1** Validate against `featuresCommandOverview.md`
  - **Scripts Summary Table**: Verify all 7 rows implemented, TAB working, help updated
  - **Aliases Summary Table**: Verify all 7 rows implemented, TAB working, help updated
  - **Configs Summary Table**: Verify all 7 rows implemented, TAB working, help updated
  - **Removals**: Confirm edit, init (scripts), rename, reload, sync removed
  - **Global Reload**: Confirm `dr reload` sources ~/.drrc

- [ ] **7.2** Run comprehensive test scenarios
  - **Scripts Tests**:
    - `dr scriptname` runs script
    - `dr set scriptname` creates/edits script
    - `dr move script1 script2` with preview and confirmation
    - `dr rm scriptname` with confirmation
    - `dr help scriptname` shows documentation
    - `dr -l` shows tree short format
    - `dr -L` shows tree long format with descriptions
    - All work with `-s` flag identically
    - TAB completion for all commands
  - **Aliases Tests**:
    - `dr -a aliasname` opens editor (default)
    - `dr -a move alias1 alias2` with preview and confirmation
    - `dr -a rm aliasname` with confirmation
    - `dr -a help aliasname` shows documentation
    - `dr -a init` creates folder structure
    - `dr -a -l` shows tree short format
    - `dr -a -L` shows tree long format
    - All work with `dr aliases` identically
    - TAB completion for all commands
  - **Configs Tests**:
    - `dr -c configname` opens editor (default)
    - `dr -c move config1 config2` with preview and confirmation
    - `dr -c rm configname` with confirmation
    - `dr -c help configname` shows documentation
    - `dr -c init` creates folder structure
    - `dr -c -l` shows tree short format
    - `dr -c -L` shows tree long format
    - All work with `dr config` identically
    - TAB completion for all commands
  - **Global Tests**:
    - `dr reload` sources ~/.drrc successfully
  - **Negative Tests** (should fail gracefully):
    - `dr edit` (removed)
    - `dr init` in scripts context (removed)
    - `dr rename` (removed)
    - `dr -s reload` (removed)
    - `dr -a reload` (removed)
    - `dr sync` (removed)

- [ ] **7.3** Document test results
  - Create test results summary
  - Note any edge cases discovered
  - Document any deviations from requirements (if any)

- [ ] **7.4** Update OpenSpec change status
  - Mark tasks.md as complete
  - Update proposal.md if needed
  - Prepare for archive

- [ ] **7.5** Archive OpenSpec change
  - Use `openspec:archive` skill or manual process
  - Move to archive with completion date
  - Update project documentation references

**Phase 7 Completion Criteria**:

- ✅ All requirements validated
- ✅ All tests passing
- ✅ Documentation complete
- ✅ OpenSpec change archived

---

## Summary Table

| Phase     | Name                          | Tasks               | Dependencies                 | Status          |
| --------- | ----------------------------- | ------------------- | ---------------------------- | --------------- |
| 1         | Scripts Namespace Cleanup     | 1.1-1.12 (12 tasks) | None                         | ⬜ Not Started  |
| 2         | Aliases Namespace Enhancement | 2.1-2.10 (10 tasks) | Phase 1 (for consistency)    | ⬜ Not Started  |
| 3         | Configs Namespace Enhancement | 3.1-3.10 (10 tasks) | Phase 1, 2 (for consistency) | ⬜ Not Started  |
| 4         | Global Reload Command         | 4.1-4.4 (4 tasks)   | Phase 1                      | ⬜ Not Started  |
| 5         | TAB Completion Unification    | 5.1-5.6 (6 tasks)   | Phase 1, 2, 3                | ⬜ Not Started  |
| 6         | Documentation Update          | 6.1-6.5 (5 tasks)   | Phase 1-5                    | ⬜ Not Started  |
| 7         | Validation and Archive        | 7.1-7.5 (5 tasks)   | All previous phases          | ⬜ Not Started  |
| **TOTAL** | **All Phases**                | **52 tasks**        | -                            | **0% Complete** |

---

## Quick Reference: Command Changes

### Scripts (`dr` / `dr -s`)

- ✅ **Keep**: run (default), set, move, help, -l, -L
- ❌ **Remove**: edit, init, rename, reload, sync, remove
- ➕ **Add**: rm

### Aliases (`dr -a` / `dr aliases`)

- ✅ **Keep**: edit (default), move, help, init, rm
- ❌ **Remove**: edit (command), set (now default), rename, reload, sync, remove
- ➕ **Add**: -l, -L

### Configs (`dr -c` / `dr config`)

- ✅ **Keep**: edit (default), move, help, init, rm
- ❌ **Remove**: edit (command), set (now default), rename, reload, sync, remove
- ➕ **Add**: -l, -L

### Global

- ➕ **Add**: reload (feature-agnostic)

---

## Notes

1. **Default Behavior Changes**:
   - Scripts: remains `run` (executes script)
   - Aliases: changes to `edit` (opens editor, no `set` needed)
   - Configs: changes to `edit` (opens editor, no `set` needed)

2. **Move Command Bug Fix**:
   - Current bug: `dr move file folder/` results in `folder/.sh`
   - Fix: preserve filename when target ends with `/`

3. **TAB Completion Consistency**:
   - All features should match Scripts style
   - Same tree view, same hint format
   - Adapted colors/icons per feature

4. **Confirmation Prompts**:
   - Move: show colored preview, confirm with [Y/y/enter]
   - Remove/rm: confirm deletion
   - Both show clear success messages

5. **List Commands**:
   - `-l`: short format (folders + names)
   - `-L`: long format (folders + names + descriptions)
   - Tree colored view for all

---

**Document Version**: 1.0
**Created**: 2026-01-22
**Requirements Source**: `/home/user/dotrun/featuresCommandOverview.md`
**Total Tasks**: 52
**Estimated Completion**: 7 phases
