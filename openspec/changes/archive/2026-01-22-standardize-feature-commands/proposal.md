# Standardize Feature Commands

## Summary

Standardize command naming, default behaviors, and available operations across all dotrun features (Scripts, Aliases, Configs) to create a consistent, intuitive user experience. This change removes inconsistencies, streamlines command sets, and establishes clear default actions for each feature type.

**IMMUTABLE REQUIREMENTS:** This proposal implements the specifications defined in `/home/user/dotrun/featuresCommandOverview.md` (the source of truth for all requirements, command behaviors, and TAB completion scenarios).

**Key Changes:**

- **SCRIPTS:** Remove 5 commands, add `rm` implementation, establish RUN as default action
- **ALIASES:** Remove explicit `set` requirement, add 3 commands (`-l`, `-L`, `move`), establish ADD/EDIT as default action
- **CONFIGS:** Identical changes to ALIASES for consistency
- **GLOBAL:** Add `dr reload` command for full environment reload
- **TAB COMPLETION:** Update all hint messages, remove obsolete completions, add new completions

## Why

### Current Problems

**1. Command Inconsistency Across Features**

Different features use different command names for the same operation:

- SCRIPTS has `remove`, ALIASES/CONFIGS may use different terminology
- SCRIPTS has `rename` but it should be unified with `move`
- Some features have `edit`, `reload`, `sync` commands that don't exist or should be removed

**2. Unclear Default Behaviors**

Users must explicitly specify actions even for the most common use case:

- SCRIPTS: Most common action is RUN, but no clear default
- ALIASES/CONFIGS: Most common action is ADD/EDIT, but `set` is required
- Inconsistent behavior confuses users switching between features

**3. Missing Critical Commands**

- SCRIPTS: No `rm` command (deletion not implemented)
- ALIASES/CONFIGS: No `-l` or `-L` for quick listing
- ALIASES/CONFIGS: No `move` command for reorganization
- No global `reload` command to refresh entire environment

**4. Tab Completion Issues**

- Hint messages don't clearly communicate available commands
- Obsolete commands still show in completions
- `-s` variants don't work identically to non-flag versions
- Missing completions for needed commands

**5. Documentation Debt**

Commands referenced in code, help messages, and documentation don't match actual implementation or desired behavior.

### User Impact

**Before (Current):**

```bash
# SCRIPTS - unclear what happens without command
❯ dr my-script              # Does it run? Edit? Error?

# ALIASES - verbose even for common action
❯ dr -a set my-alias        # "set" required even though it's 90% of usage

# SCRIPTS - can't delete
❯ dr remove my-script       # Command doesn't exist

# ALIASES - can't list quickly
❯ dr -a -l                  # Command doesn't exist

# Tab hints don't help
❯ dr <TAB>
(hint: -s/scripts, -a/aliases, -c/config)  # What commands are available?
```

**After (This Change):**

```bash
# SCRIPTS - intuitive default (RUN)
❯ dr my-script              # ✓ Runs the script

# ALIASES - intuitive default (ADD/EDIT)
❯ dr -a my-alias            # ✓ Opens for editing

# SCRIPTS - deletion works
❯ dr rm my-script           # ✓ Removes script

# ALIASES - listing works
❯ dr -a -l                  # ✓ Shows tree view

# Tab hints are actionable
❯ dr <TAB>
(hint: run (default), -l, -L, set, move, rm, help)
📁 folder1/
🚀 my-script

# Global reload
❯ dr reload                 # ✓ Reloads entire dotrun environment
```

## What Changes

### 1. SCRIPTS Namespace Changes

**Reference:** `/home/user/dotrun/featuresCommandOverview.md` Section: "Scripts" and "SUMMARY"

**Default Behavior Change:**

- **NEW:** When no command specified, RUN the script (default action)
- **BEFORE:** Behavior was unclear/inconsistent

**Command Removals:**

- Remove `edit` command - not needed, use `set` to open editor
- Remove `init` command - not applicable to scripts
- Remove `reload` command - moving to global scope
- Remove `sync` command - not implemented/not needed

**Command Renames:**

- Rename `remove` → `rm` (standardize on Unix convention)

**Command Additions:**

- Implement `rm` command for script deletion
- Ensure `help` command works for all scripts

**Final Command Set:**

```bash
dr [SCRIPT_NAME]    # RUN (default)
dr -l [FOLDER/]     # LIST (short format)
dr -L [FOLDER/]     # LIST (long format with descriptions)
dr set SCRIPT_NAME  # ADD/EDIT
dr move SCRIPT_NAME # MOVE/RENAME
dr rm SCRIPT_NAME   # REMOVE
dr help SCRIPT_NAME # HELP
```

**Flag Consistency:**

- `dr -s SCRIPT_NAME` must work identically to `dr SCRIPT_NAME`
- `dr -s -l` must work identically to `dr -l`
- All `-s` variants must have identical behavior to non-flag versions

### 2. ALIASES Namespace Changes

**Reference:** `/home/user/dotrun/featuresCommandOverview.md` Section: "ALIASES"

**Default Behavior Change:**

- **NEW:** When no command specified, ADD/EDIT the alias (opens in editor)
- **BEFORE:** Required explicit `set` command

**Command Removals:**

- Remove explicit `set` requirement (it becomes optional, default behavior is ADD/EDIT)
- Remove `edit` command - redundant with new default behavior
- Remove `reload` command - moving to global scope
- Remove `sync` command - not implemented/not needed

**Command Renames:**

- Rename `remove` → `rm` (standardize on Unix convention)

**Command Additions:**

- Add `-l [FOLDER/]` command - list aliases in tree view (short format)
- Add `-L [FOLDER/]` command - list aliases in tree view (long format with descriptions)
- Add `move` command - move/rename alias files
- Add `help` command - display alias documentation

**Commands Kept:**

- Keep `init` command - initializes alias folder structure

**Final Command Set:**

```bash
dr -a ALIAS_NAME      # ADD/EDIT (default)
dr -a -l [FOLDER/]    # LIST (short format)
dr -a -L [FOLDER/]    # LIST (long format)
dr -a set ALIAS_NAME  # ADD/EDIT (explicit, same as default)
dr -a move ALIAS_NAME # MOVE/RENAME
dr -a rm ALIAS_NAME   # REMOVE
dr -a help ALIAS_NAME # HELP
dr -a init [FOLDER/]  # INIT folder structure
```

### 3. CONFIGS Namespace Changes

**Reference:** `/home/user/dotrun/featuresCommandOverview.md` Section: "CONFIGS"

**Identical to ALIASES changes** - ensures consistency across non-executable features.

**Default Behavior Change:**

- **NEW:** When no command specified, ADD/EDIT the config (opens in editor)
- **BEFORE:** Required explicit `set` command

**Command Removals:**

- Remove explicit `set` requirement (it becomes optional, default behavior is ADD/EDIT)
- Remove `edit` command - redundant with new default behavior
- Remove `reload` command - moving to global scope
- Remove `sync` command - not implemented/not needed

**Command Renames:**

- Rename `remove` → `rm` (standardize on Unix convention)

**Command Additions:**

- Add `-l [FOLDER/]` command - list configs in tree view (short format)
- Add `-L [FOLDER/]` command - list configs in tree view (long format with descriptions)
- Add `move` command - move/rename config files
- Add `help` command - display config documentation

**Commands Kept:**

- Keep `init` command - initializes config folder structure

**Final Command Set:**

```bash
dr -c CONFIG_NAME      # ADD/EDIT (default)
dr -c -l [FOLDER/]     # LIST (short format)
dr -c -L [FOLDER/]     # LIST (long format)
dr -c set CONFIG_NAME  # ADD/EDIT (explicit, same as default)
dr -c move CONFIG_NAME # MOVE/RENAME
dr -c rm CONFIG_NAME   # REMOVE
dr -c help CONFIG_NAME # HELP
dr -c init [FOLDER/]   # INIT folder structure
```

### 4. Global Commands

**Reference:** `/home/user/dotrun/featuresCommandOverview.md` Section: "EXTRA"

**New Global Command:**

```bash
dr reload # Reload entire dotrun environment (sources ~/.drrc)
```

**Purpose:** Feature-agnostic command that reloads the entire dotrun tool by sourcing `~/.drrc`. Replaces feature-specific reload commands.

**Behavior:**

- Sources `~/.drrc` file
- Reloads all aliases, scripts, configs, and environment settings
- Works from any shell (bash, zsh, fish)
- Returns success/failure status

### 5. Tab Completion Changes

**Reference:** `/home/user/dotrun/featuresCommandOverview.md` Section: "TAB autocomplete shell scenarios"

**All Changes Apply To:**

- ZSH completion: `core/shared/dotrun/shell/zsh/dr_completion.zsh`
- Bash completion: `core/shared/dotrun/shell/bash/dr_completion.bash`
- Bash-ble completion: `core/shared/dotrun/shell/bash/dr_completion_ble.sh`
- Fish completion: `core/shared/dotrun/shell/fish/dr_completion.fish`

**Hint Message Updates:**

**SCRIPTS (default/`-s` flag):**

```bash
# OLD
❯ dr <TAB>
(hint: -s/scripts, -a/aliases, -c/config, -col/collections)

# NEW
❯ dr <TAB>
(hint: run (default), -l, -L, set, move, rm, help)
📁 folder1/
🚀 my-script
```

**ALIASES (`-a` flag):**

```bash
# NEW
❯ dr -a <TAB>
(hint: add/edit (default), -l, -L, move, rm, help, init)
📁 folder1/
📝 my-alias
```

**CONFIGS (`-c` flag):**

```bash
# NEW
❯ dr -c <TAB>
(hint: add/edit (default), -l, -L, move, rm, help, init)
📁 folder1/
⚙️  my-config
```

**Remove Completions For:**

- `edit` (all features)
- `init` (scripts only - keep for aliases/configs)
- `rename` (all features - use `move` instead)
- `reload` (all features - use global `dr reload`)
- `sync` (all features)
- `remove` (all features - use `rm` instead)

**Add Completions For:**

- `rm` (all features)
- `-l` flag (aliases, configs)
- `-L` flag (aliases, configs)
- `move` (aliases, configs)
- `help` (aliases, configs - already exists for scripts)
- `reload` (global command, no feature flag)

**Flag Consistency Requirements:**

- `dr -s COMMAND` must autocomplete identically to `dr COMMAND`
- `dr -a COMMAND` must autocomplete with alias-specific items
- `dr -c COMMAND` must autocomplete with config-specific items

**Specific Scenarios (from requirements doc):**

**ST1 - Default TAB:**

```bash
dr <TAB>
# Shows: hint message + folders + scripts (not other features)
dr -s <TAB>
# Identical to above
```

**ST2 - `set` command:**

```bash
dr set <TAB>
# Shows: folders + scripts
dr -s set <TAB>
# Identical to above
```

**ST6 - `move` command:**

```bash
dr move <TAB>
# Shows: folders + scripts
# After selection, shows confirmation with colors
dr -s move <TAB>
# Identical to above
```

**ST8 - `rm` command (NEW):**

```bash
dr rm <TAB>
# Shows: folders + scripts
dr -s rm <TAB>
# Identical to above
```

### 6. Code Changes Required

**Files to Modify:**

1. **`core/shared/dotrun/dr`** (main executable)
   - Update command routing logic for all three features
   - Add default action handling (run for scripts, add/edit for aliases/configs)
   - Implement `rm` command for scripts
   - Add global `reload` command
   - Remove routing for: `edit`, `init` (scripts), `rename`, `reload` (features), `sync`
   - Update command name: `remove` → `rm`

2. **`core/shared/dotrun/shell/zsh/dr_completion.zsh`**
   - Update hint messages for all features
   - Remove completions for removed commands
   - Add completions for new commands (`rm`, `-l`, `-L`, `move`, `help`)
   - Ensure `-s` variants work identically
   - Add global `reload` completion

3. **`core/shared/dotrun/shell/bash/dr_completion.bash`**
   - Same changes as ZSH completion

4. **`core/shared/dotrun/shell/bash/dr_completion_ble.sh`**
   - Same changes as ZSH completion

5. **`core/shared/dotrun/shell/fish/dr_completion.fish`**
   - Same changes as ZSH completion

6. **Help/Documentation Files** (if they exist)
   - Search codebase for references to removed commands
   - Update inline help messages in `dr` script
   - Update any `.md` documentation files
   - Update any command labels/descriptions

**Implementation Notes:**

**For `move` command bug fix (mentioned in requirements):**

```bash
# Current bug: dr move folder1/file folder1/folder2/
# Result: folder1/folder2/.sh (filename lost)

# Fix: Detect if target ends with '/' and preserve source filename
# Result: folder1/folder2/file.sh
```

**For `move` command confirmation:**

```bash
# Show colored preview before executing
# Example:
# Move: folder1/file.sh → folder2/newfile.sh
# Confirm? [Y/y/Enter to proceed, any other key to cancel]
```

### 7. Documentation Updates

**Files to Check and Update:**

Search entire codebase for references to:

- `dr edit`
- `dr init` (in scripts context)
- `dr rename`
- `dr reload` (in feature context)
- `dr sync`
- `dr remove`
- `dr -s edit`, `dr -a edit`, `dr -c edit`
- Similar patterns for all removed commands

**Update:**

- `README.md` - if it documents commands
- `CHANGELOG.md` - add entry for this breaking change
- Any `commands.md` or similar documentation
- Inline `--help` messages
- Comment blocks in code

## Impact

### Affected Files (Direct Modifications)

**Core Implementation:**

- `/home/user/dotrun/core/shared/dotrun/dr` - Main executable, command routing
- `/home/user/dotrun/core/shared/dotrun/VERSION` - Version bump for release

**Shell Completions:**

- `/home/user/dotrun/core/shared/dotrun/shell/zsh/dr_completion.zsh` - ZSH completions
- `/home/user/dotrun/core/shared/dotrun/shell/bash/dr_completion.bash` - Bash completions
- `/home/user/dotrun/core/shared/dotrun/shell/bash/dr_completion_ble.sh` - Bash-ble completions
- `/home/user/dotrun/core/shared/dotrun/shell/fish/dr_completion.fish` - Fish completions

**Documentation:**

- `/home/user/dotrun/README.md` - User-facing documentation
- `/home/user/dotrun/CHANGELOG.md` - Release notes
- `/home/user/dotrun/commands.md` - Command reference (if exists)
- Any other `.md` files with command examples

### Affected Specs

This change impacts the following OpenSpec specifications:

**Modified Specs:**

- `specs/features/scripts.md` - Update command list, default behavior
- `specs/features/aliases.md` - Update command list, default behavior
- `specs/features/configs.md` - Update command list, default behavior
- `specs/core/commands.md` - Add global `reload` command
- `specs/shell-integration/completion.md` - Update completion behaviors

**New Specs (if they don't exist):**

- May need to create spec files for features if they don't exist

### Benefits

**Consistency:**

- All features use identical command names for same operations
- `-s`/`-a`/`-c` flags work identically to their non-flag equivalents
- Unix conventions (`rm` instead of `remove`) applied uniformly

**Usability:**

- Intuitive defaults reduce typing for common operations
- Clear hint messages guide users to available commands
- Tab completion shows only valid, implemented commands

**Discoverability:**

- Users can learn one feature and apply knowledge to others
- Help messages accurately reflect available commands
- No ghost commands in completions

**Maintainability:**

- Remove dead code paths for unimplemented commands
- Documentation matches implementation
- Clear separation between feature-specific and global commands

### Breaking Changes

**CRITICAL - User Impact:**

This is a **MAJOR BREAKING CHANGE** that requires user action.

**Commands Removed (will fail if used):**

```bash
dr edit SCRIPT    # ❌ No longer valid
dr -a edit ALIAS  # ❌ No longer valid
dr -c edit CONFIG # ❌ No longer valid

dr init SCRIPT    # ❌ No longer valid (scripts only)
dr -s init SCRIPT # ❌ No longer valid

dr rename ANYTHING  # ❌ No longer valid
dr -s rename SCRIPT # ❌ No longer valid
dr -a rename ALIAS  # ❌ No longer valid
dr -c rename CONFIG # ❌ No longer valid

dr remove SCRIPT    # ❌ No longer valid
dr -s remove SCRIPT # ❌ No longer valid
dr -a remove ALIAS  # ❌ No longer valid (use 'rm')
dr -c remove CONFIG # ❌ No longer valid (use 'rm')

dr reload    # ✓ Valid (moved to global, different behavior)
dr -s reload # ❌ No longer valid
dr -a reload # ❌ No longer valid
dr -c reload # ❌ No longer valid

dr sync    # ❌ No longer valid
dr -s sync # ❌ No longer valid
dr -a sync # ❌ No longer valid
dr -c sync # ❌ No longer valid
```

**Migration Guide for Users:**

| Old Command         | New Command     | Notes                           |
| ------------------- | --------------- | ------------------------------- |
| `dr edit SCRIPT`    | `dr set SCRIPT` | Opens editor                    |
| `dr -a edit ALIAS`  | `dr -a ALIAS`   | Default behavior                |
| `dr -c edit CONFIG` | `dr -c CONFIG`  | Default behavior                |
| `dr init SCRIPT`    | N/A             | Not applicable to scripts       |
| `dr rename X`       | `dr move X`     | Works for all features          |
| `dr remove X`       | `dr rm X`       | Works for all features          |
| `dr -s reload`      | `dr reload`     | Global reload (sources ~/.drrc) |
| `dr sync`           | N/A             | Not implemented/not needed      |

**Behavioral Changes:**

```bash
# OLD: Unclear what happens
❯ dr my-script
# (behavior was undefined or required explicit 'run')

# NEW: Runs the script
❯ dr my-script
Running my-script...

# OLD: Required explicit 'set'
❯ dr -a my-alias
Error: command required

# NEW: Opens in editor (default)
❯ dr -a my-alias
Opening my-alias in $EDITOR...

# OLD: Required explicit 'set'
❯ dr -c my-config
Error: command required

# NEW: Opens in editor (default)
❯ dr -c my-config
Opening my-config in $EDITOR...
```

### Migration Strategy

**Version Bump:**

- This requires a MAJOR version bump (e.g., 3.0.0 → 4.0.0)
- CHANGELOG.md must prominently document breaking changes

**User Communication:**

1. Release notes must include migration guide
2. Consider deprecation warnings in 3.x versions before removal
3. Update all public documentation before release

**Backward Compatibility:**

- **NOT MAINTAINED** - Clean break for consistency
- Users must update command usage after upgrade

## Validation Criteria

**Functional Validation:**

**Scripts Namespace:**

- [ ] `dr my-script` executes the script (default RUN behavior)
- [ ] `dr set my-script` opens script in editor
- [ ] `dr move old-name new-name` renames/moves script
- [ ] `dr move folder1/file folder2/` preserves filename (bug fix)
- [ ] `dr move` shows colored confirmation before executing
- [ ] `dr rm my-script` deletes script (NEW command)
- [ ] `dr help my-script` displays script documentation
- [ ] `dr -l` shows short tree view of scripts
- [ ] `dr -L` shows long tree view with descriptions
- [ ] `dr -s COMMAND` works identically to `dr COMMAND` for all commands

**Aliases Namespace:**

- [ ] `dr -a my-alias` opens alias in editor (default ADD/EDIT behavior)
- [ ] `dr -a set my-alias` opens alias in editor (explicit, same as default)
- [ ] `dr -a move old-name new-name` renames/moves alias
- [ ] `dr -a rm my-alias` deletes alias
- [ ] `dr -a help my-alias` displays alias documentation
- [ ] `dr -a -l` shows short tree view of aliases (NEW)
- [ ] `dr -a -L` shows long tree view with descriptions (NEW)
- [ ] `dr -a init` initializes alias folder structure

**Configs Namespace:**

- [ ] `dr -c my-config` opens config in editor (default ADD/EDIT behavior)
- [ ] `dr -c set my-config` opens config in editor (explicit, same as default)
- [ ] `dr -c move old-name new-name` renames/moves config
- [ ] `dr -c rm my-config` deletes config
- [ ] `dr -c help my-config` displays config documentation
- [ ] `dr -c -l` shows short tree view of configs (NEW)
- [ ] `dr -c -L` shows long tree view with descriptions (NEW)
- [ ] `dr -c init` initializes config folder structure

**Global Commands:**

- [ ] `dr reload` sources `~/.drrc` and reloads environment (NEW)
- [ ] `dr reload` works in bash, zsh, and fish shells

**Removed Commands Fail:**

- [ ] `dr edit SCRIPT` returns error with helpful message
- [ ] `dr -a edit ALIAS` returns error with helpful message
- [ ] `dr -c edit CONFIG` returns error with helpful message
- [ ] `dr init SCRIPT` returns error with helpful message
- [ ] `dr rename ANYTHING` returns error suggesting `move`
- [ ] `dr remove ANYTHING` returns error suggesting `rm`
- [ ] `dr -s reload` returns error suggesting global `dr reload`
- [ ] `dr sync` returns error

**Tab Completion Validation:**

**ZSH Completions:**

- [ ] `dr <TAB>` shows hint: "run (default), -l, -L, set, move, rm, help"
- [ ] `dr <TAB>` shows folders + scripts (no other features)
- [ ] `dr -s <TAB>` identical to `dr <TAB>`
- [ ] `dr set <TAB>` shows folders + scripts
- [ ] `dr -s set <TAB>` identical to `dr set <TAB>`
- [ ] `dr move <TAB>` shows folders + scripts
- [ ] `dr rm <TAB>` shows folders + scripts (NEW)
- [ ] `dr help <TAB>` shows folders + scripts
- [ ] `dr -a <TAB>` shows hint: "add/edit (default), -l, -L, move, rm, help, init"
- [ ] `dr -a <TAB>` shows folders + aliases
- [ ] `dr -a -l <TAB>` shows folders only (for filtering)
- [ ] `dr -a move <TAB>` shows folders + aliases (NEW)
- [ ] `dr -a rm <TAB>` shows folders + aliases
- [ ] `dr -a help <TAB>` shows folders + aliases (NEW)
- [ ] `dr -c <TAB>` shows hint: "add/edit (default), -l, -L, move, rm, help, init"
- [ ] `dr -c <TAB>` shows folders + configs
- [ ] `dr -c -l <TAB>` shows folders only (for filtering) (NEW)
- [ ] `dr -c move <TAB>` shows folders + configs (NEW)
- [ ] `dr -c rm <TAB>` shows folders + configs
- [ ] `dr -c help <TAB>` shows folders + configs (NEW)
- [ ] `dr reload <TAB>` shows nothing (command takes no arguments)
- [ ] Removed commands show NO completions: `edit`, `init` (scripts), `rename`, `reload` (features), `sync`, `remove`

**Bash Completions:**

- [ ] Same validation as ZSH (all checks above)

**Fish Completions:**

- [ ] Same validation as ZSH (all checks above)

**Documentation Validation:**

- [ ] `README.md` references only valid commands
- [ ] `CHANGELOG.md` documents breaking changes
- [ ] `commands.md` (if exists) updated with new command set
- [ ] No references to removed commands in any `.md` files
- [ ] Inline `--help` messages show correct command sets
- [ ] Code comments don't reference obsolete commands

**Technical Validation:**

- [ ] All shell completion files (zsh, bash, bash-ble, fish) updated consistently
- [ ] No dead code paths for removed commands remain
- [ ] Version number bumped appropriately (MAJOR version)
- [ ] `openspec validate standardize-feature-commands --strict` passes

## Success Criteria

**User Experience:**

- [ ] Users can execute most common actions with minimal typing
  - `dr my-script` to run
  - `dr -a my-alias` to edit
  - `dr -c my-config` to edit
- [ ] Tab completion guides users to available commands via clear hints
- [ ] Error messages for removed commands explain migration path
- [ ] All three features (scripts, aliases, configs) feel consistent

**Implementation:**

- [ ] Zero references to removed commands in codebase
- [ ] All completion files updated and tested
- [ ] Migration guide published in release notes
- [ ] Version bumped to reflect breaking changes

**Consistency:**

- [ ] SCRIPTS, ALIASES, and CONFIGS share identical command names (where applicable)
- [ ] `-s`/`-a`/`-c` flags work identically to non-flag variants
- [ ] Unix conventions (`rm`, `move`) applied uniformly
- [ ] Default behaviors clearly documented and intuitive

**Quality:**

- [ ] No regressions in existing functionality
- [ ] All new commands (`rm`, `-l`, `-L`, `move`, `help`) work correctly
- [ ] Global `reload` command works across all shells
- [ ] Tab completion performance unchanged

## Dependencies

**Blocked By:**

- None

**Blocks:**

- Any future feature additions should follow this standardized pattern

**Related Changes:**

- `fix-zsh-recursive-completion` - Tab completion infrastructure used by this change
- `update-documentation-system` - Documentation updates needed for new commands

## Alternatives Considered

### Alternative 1: Keep All Existing Commands

**Approach:** Add new commands but maintain backward compatibility with old command names.

**Rejected Because:**

- Increases maintenance burden (two ways to do everything)
- Doesn't solve consistency problem
- Confuses new users with multiple options
- Completion menus become cluttered

### Alternative 2: Deprecation Period

**Approach:** Show warnings for 1-2 versions before removing commands.

**Considered But Not Implemented:**

- Adds complexity to this change
- Can be added in implementation phase if desired
- Would require maintaining both old and new code paths temporarily
- Could be good for user migration but delays consistency benefits

### Alternative 3: Different Default for Scripts

**Approach:** Make `dr SCRIPT` require explicit `run` command (matching aliases/configs pattern).

**Rejected Because:**

- Scripts are primarily for execution - that should be the easiest action
- Different default behaviors for different feature types make sense:
  - SCRIPTS: Run (executable)
  - ALIASES: Edit (configuration)
  - CONFIGS: Edit (configuration)
- Users expect `dr my-script` to execute, not open editor

### Alternative 4: Keep `remove` Instead of `rm`

**Approach:** Use `remove` as the standard command across all features.

**Rejected Because:**

- `rm` is more concise and follows Unix conventions
- Users familiar with shell will expect `rm`
- Shorter command for a potentially destructive action is acceptable (requires typing full word)
- Consistency with broader ecosystem (git, npm, etc. use `rm`)

### Alternative 5: Feature-Specific Reload Commands

**Approach:** Keep `dr -s reload`, `dr -a reload`, `dr -c reload` separate.

**Rejected Because:**

- No clear use case for reloading only one feature
- Reloading is typically needed after config changes that affect everything
- Global `dr reload` is simpler and clearer
- Reduces command surface area

## Notes

**Implementation Order:**

1. Update main `dr` executable with command routing logic
2. Implement `rm` command for scripts
3. Implement `-l` and `-L` for aliases/configs
4. Add global `reload` command
5. Update all four shell completion files consistently
6. Update documentation (README, CHANGELOG, commands.md)
7. Search and remove all references to obsolete commands
8. Version bump and release preparation

**Testing Priority:**

High priority (core functionality):

- Default behaviors (run for scripts, add/edit for aliases/configs)
- New `rm` command implementation
- Global `reload` command
- Tab completion hint messages

Medium priority (enhancements):

- `-l` and `-L` listing commands
- `move` command bug fix (preserve filename)
- `move` command confirmation UI

Low priority (cleanup):

- Error messages for removed commands
- Documentation updates
- Dead code removal

**Risk Mitigation:**

- Create comprehensive test suite before implementation
- Manual testing checklist for all completion scenarios
- Rollback plan: maintain v3.x branch for critical fixes
- Clear migration documentation in release notes
