# New Collections System Design

## Overview

Simplified, interactive collections system that stores GitHub repository URLs and allows selective resource import.

## Configuration File: `~/.dr.conf`

Location: `$HOME/.dr.conf`
Format:

```ini
# DotRun Collections Configuration
[collections]
https://github.com/user/dotrun-scripts.git
https://github.com/company/team-scripts.git
https://github.com/community/awesome-scripts.git
```

## Expected Repository Structure

```
repository/
├── bin/              # Executable scripts
│   ├── deploy.sh
│   ├── test.sh
│   └── category/
│       └── script.sh
├── aliases/          # Alias definitions
│   ├── git.aliases
│   └── docker.aliases
├── helpers/          # Helper modules
│   ├── custom.sh
│   └── utils.sh
└── configs/          # Configuration files
    ├── api.config
    └── database.config
```

## User Flow

### 1. Add Collection

```bash
$ dr collections add https://github.com/user/scripts.git
✓ Collection URL added to ~/.dr.conf
```

### 2. Interactive Selection

```bash
$ dr collections

========================================
  DotRun Collections Manager
========================================

[1] Select Collection:
  1) user/scripts (https://github.com/user/scripts.git)
  2) company/team-scripts (https://github.com/company/team-scripts.git)
  3) community/awesome-scripts (https://github.com/community/awesome-scripts.git)

  a) Add new collection
  r) Remove collection
  q) Quit

Select [1-3/a/r/q]: 1

Fetching collection...
✓ Collection cloned to cache

[2] Select Resource Type:
  1) Scripts (bin/)
  2) Aliases (aliases/)
  3) Helpers (helpers/)
  4) Configs (configs/)

  b) Back
  q) Quit

Select [1-4/b/q]: 1

[3] Available Scripts:
  1) deploy.sh
  2) test.sh
  3) category/script.sh

  *) Select by number (e.g., 1,3)
  a) Add all
  b) Back
  q) Quit

Select [numbers/a/b/q]: 1,3

Adding deploy.sh...
  ✓ Copied to ~/.config/dotrun/bin/deploy.sh
  ✓ Made executable

Adding category/script.sh...
  ✓ Copied to ~/.config/dotrun/bin/category/script.sh
  ✓ Made executable

Successfully added 2 scripts!
Run with: dr <scriptname>
```

## Commands

### `dr collections add <url>`

- Validates GitHub URL
- Adds to `~/.dr.conf`
- Creates config file if doesn't exist

### `dr collections list`

- Shows saved collection URLs
- Shows number format

### `dr collections remove <number>`

- Removes collection URL from config

### `dr collections` (interactive)

- Main interactive flow
- Step 1: Pick collection
- Step 2: Pick resource type
- Step 3: Pick specific resources
- Copies to local ~/.config/dotrun/

## Implementation Details

### Cache Management

- Collections cloned to: `~/.config/dotrun/.cache/collections/<hash>/`
- Cache cleared after selection or on demand
- Temporary clones, not persistent

### Name Conflict Handling

- If resource exists, prompt: [O]verwrite, [R]ename, [S]kip
- Rename adds suffix: `script-1.sh`, `script-2.sh`

### Error Handling

- Invalid GitHub URLs rejected
- Missing resource types show warning
- Clone failures show git error
- Empty repositories handled gracefully

## Documentation Changes

### Remove docs/ Folder System

- Delete `DOC_DIR` variable usage
- Remove all `docs/` references
- Keep only inline `### DOC` documentation
- Remove `dr edit:docs` command
- Remove `dr docs` command (keep `dr help` for inline docs)

### Inline Documentation Only

Scripts use only `### DOC` markers:

```bash
#!/usr/bin/env bash
### DOC
# scriptname - Short description
# Usage: dr scriptname [args]
### DOC
```

## Migration Notes

### Breaking Changes

- No more separate `.md` documentation files
- Collections must follow new repository structure
- Old import/export commands removed
- No more collection metadata files (.dr-collection.yml)

### What's Kept

- `dr yadm-init` - still works for dotfile integration
- `dr help <script>` - shows inline docs
- All existing scripts continue to work

## File Changes Required

1. **helpers/collections.sh** - Complete rewrite (~200 lines)
2. **dr** - Update collections command handler
3. **drun_completion.bash** - Update collections completions
4. **drun_completion.zsh** - Update collections completions
5. **drun_completion.fish** - Update collections completions
6. **README.md** - Update collections documentation
7. **CLAUDE.md** - Update architecture notes
