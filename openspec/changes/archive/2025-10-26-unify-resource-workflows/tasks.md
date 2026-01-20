# Implementation Tasks - Unify Resource Workflows

**Status:** in-progress
**Progress:** 37/48 tasks (77%)

**Architecture Note:** Implementation uses multi-resource-per-file pattern (one file = many aliases/configs) instead of original single-resource-per-file proposal. This better matches established conventions and reduces file clutter.

## Completed Work

### Phase 1: Aliases Workflow ✅ (12/12 tasks = 100%)

- [x] 1.1.1-1.1.12: Core aliases helpers implemented
  - [x] `aliases_set()` - editor-based, idempotent
  - [x] `create_alias_file_skeleton()` - comprehensive skeleton
  - [x] `validate_editor()` - validates EDITOR
  - [x] Category folder support
  - [x] File resolution and validation
  - [x] `aliases_list()`, `aliases_remove()`, `aliases_reload()`

- [x] 1.2.1-1.2.8: Testing coverage
  - [x] Flat and categorized file creation
  - [x] List/remove/reload functionality
  - [x] Syntax validation via skeleton

### Phase 2: Config Workflow ⚠️ (12/14 tasks = 86%)

- [x] 2.1.1-2.1.10: Core config helpers implemented
  - [x] `config_set()` - editor-based, idempotent
  - [x] `create_config_file_skeleton()` - comprehensive skeleton
  - [x] `validate_editor()` - same as aliases
  - [x] Category folder support
  - [x] `config_list()`, `config_remove()`

- [ ] 2.1.11: ❌ # SECURE marker detection in config_list() - NOT implemented
- [ ] 2.1.12: ❌ # SECURE marker masking in config_get() - NOT implemented

- [x] 2.2.1-2.2.6: Partial testing coverage

### Phase 3: Command Routing ✅ (6/6 tasks = 100%)

- [x] 3.1.1-3.1.6: Dr binary updates complete
  - [x] Aliases routing: `-a|aliases` with set/list/remove/reload/init
  - [x] Config routing: `-c|config` with set/list/remove
  - [x] Help text comprehensive
  - [x] Main help updated

Note: Uses `set` command instead of `add` (intentional, better UX)

### Phase 7: Edge Cases ✅ (5/6 tasks = 83%)

- [x] 7.1: EDITOR validation complete
- [x] 7.2-7.3: Syntax validation via skeleton comments
- [x] 7.4: Category folder auto-creation
- [x] 7.5: Empty directory cleanup
- [ ] 7.6: Linter integration - uncertain status

## Remaining Work

### Phase 4: Shell Completions ❌ (0/9 tasks = 0%)

- [ ] 4.1.1-4.1.3: Bash completion updates needed
  - [ ] Update `dr aliases set` completion
  - [ ] Update `dr config set` completion

- [ ] 4.2.1-4.2.3: Zsh completion updates needed
  - [ ] Update command signatures
  - [ ] Add file/folder suggestions

- [ ] 4.3.1-4.3.3: Fish completion updates needed
  - [ ] Update command signatures
  - [ ] Add file/folder suggestions

### Phase 5: Documentation ❌ (0/6 tasks = 0%)

- [ ] 5.1: Update README.md - Aliases section
- [ ] 5.2: Update README.md - Config section
- [ ] 5.3: Add "Resource Management Philosophy" section
- [ ] 5.4: Create migration guide (v3.0 → v3.1)
- [ ] 5.5: Update detailed help for aliases
- [ ] 5.6: Update detailed help for config

### Phase 6: Integration Testing ⚠️ (2/4 tasks = 50%)

- [x] 6.1: Aliases workflow tested (manual verification)
- [x] 6.2: Config workflow partially tested
- [ ] 6.3: Cross-shell testing (Bash, Zsh, Fish) - not documented
- [ ] 6.4: Cross-shell config testing - not documented

## Critical Missing Features

### 1. # SECURE Marker System (High Priority)

**Goal:** Mark sensitive config values with `# SECURE` comment, mask them in output

**Required Changes:**

- Update `config_list()` to detect `# SECURE` comments above exports
- Mask values in list output (show `****` instead of actual value)
- Add `config_get()` function with optional `--show-value` flag
- Remove dependency on `.secure_keys` external file

**Implementation Notes:**

```bash
# In config file:
# SECURE
export API_KEY="sensitive-value"

# In config_list() output:
API_KEY=**** [SECURE]

# With --show-value flag:
API_KEY="sensitive-value" [SECURE]
```

### 2. Shell Completions (Medium Priority)

**Bash:** Update `core/shared/dotrun/shell/bash/dr_completion.bash`

- Complete `dr aliases set <tab>` with existing file suggestions
- Complete `dr config set <tab>` with existing file suggestions

**Zsh:** Update `core/shared/dotrun/shell/zsh/dr_completion.zsh`

- Update command signatures
- Add folder navigation support

**Fish:** Update `core/shared/dotrun/shell/fish/dr_completion.fish`

- Update command signatures
- Add file suggestions

### 3. Documentation (Medium Priority)

**README.md Updates:**

- Replace old command examples with new `set` command
- Show multi-resource file pattern
- Explain numbered file convention (01-category.aliases)

**Migration Guide:**

- Create `docs/MIGRATION-v3.0-to-v3.1.md`
- Old vs new command comparison
- Example migrations for existing users

## Success Criteria

- [x] Aliases use editor-based workflow
- [x] Config uses editor-based workflow
- [x] Category folders work
- [ ] # SECURE markers implemented
- [x] Help text accurate
- [ ] Shell completions updated
- [ ] Documentation updated
- [ ] All shells tested

## Next Steps

**Priority 1:** Implement # SECURE marker system
**Priority 2:** Update shell completions
**Priority 3:** Update documentation
**Priority 4:** Cross-shell testing

**Timeline Estimate:**

- # SECURE markers: 2-3 hours
- Shell completions: 2-3 hours
- Documentation: 1-2 hours
- Testing: 1 hour

**Total remaining:** ~8 hours of work
