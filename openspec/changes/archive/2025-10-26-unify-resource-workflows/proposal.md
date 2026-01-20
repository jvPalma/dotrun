# Unify Resource Management Workflows

## Why

The current resource management system had inconsistent workflows across different resource types. Scripts used an editor-centric workflow while aliases and configs used command-line arguments, creating:

1. **Inconsistent UX** - Different mental models for each resource type
2. **Limited expressiveness** - Complex values difficult to write inline
3. **No editor features** - Missing syntax highlighting, multi-line editing
4. **Harder to review** - No preview before committing changes
5. **Copy-paste friction** - Must escape quotes and special characters

## What Changes

**Unified File-Based Workflow:**

All resource types now work like scripts - open in EDITOR for creation and editing.

**Aliases (Implemented):**

- `dr aliases set <path/to/file>` - Opens `~/.config/dotrun/aliases/<path>.aliases` in editor
- Supports category folders: `dr aliases set git/shortcuts`
- File-based: One file contains multiple aliases with numbered organization (01-git.aliases)

**Config (Implemented):**

- `dr config set <path/to/file>` - Opens `~/.config/dotrun/configs/<path>.config` in editor
- Supports category folders: `dr config set api/keys`
- File-based: One file contains multiple exports with numbered organization (01-main.config)

**Architecture Decision:**

Implementation uses **multi-resource-per-file** pattern instead of single-resource-per-file:

- Better organization: `01-git.aliases` contains all git-related aliases
- Less clutter: 10 aliases in 1 file instead of 10 separate files
- Matches established naming conventions (NN-category.{aliases,config})

## Impact

**Affected Code:**

- `core/shared/dotrun/core/aliases.sh` - New file-based workflow
- `core/shared/dotrun/core/config.sh` - New file-based workflow
- `core/shared/dotrun/dr` - Updated command routing
- Shell completions - Need updates for new commands

**Benefits:**

1. ✨ Consistency - All resources use identical workflow
2. ✨ Power - Full editor capabilities (syntax highlighting, plugins)
3. ✨ Expressiveness - Complex values easier to write
4. ✨ Discoverability - Files are visible and version-controllable
5. ✨ Safety - Preview changes before saving
6. ✨ Simplicity - Fewer command arguments
7. ✨ Integration - Editors can provide validation and linting

**Status:**

- ✅ Core implementation complete (77% of original plan)
- ✅ Aliases workflow fully functional
- ✅ Config workflow functional (missing # SECURE markers)
- ❌ Shell completions not updated
- ❌ Documentation not updated
