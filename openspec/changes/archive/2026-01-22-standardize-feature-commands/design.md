# Standardize Feature Commands - Technical Design

**OpenSpec Change ID:** standardize-feature-commands  
**Created:** 2026-01-22  
**Status:** Draft

---

## Overview

This design document details the technical implementation for standardizing command interfaces across DotRun's core features.

**IMMUTABLE REQUIREMENTS REFERENCE:** `/home/user/dotrun/featuresCommandOverview.md`

The requirements document defines WHAT must change. This design specifies HOW to implement those changes.

---

## Architecture Context

### Current Command Routing

**File:** `/home/user/dotrun/core/shared/dotrun/dr`

The main `dr` script uses case-based command parsing:

```bash
case "${1:-}" in
  -l | -L)           # List commands (scripts) - lines 517-521
  -s|scripts)        # Script namespace - lines 523-584
  set|edit|move...)  # Direct script commands - lines 586-626
  -a|aliases)        # Aliases namespace - lines 935-1001
  -c|config)         # Config namespace - lines 1003-1059
  -col|collections)  # Collections namespace - lines 635-933
  *)                 # Default: run script - lines 1124-1131
esac
```

### Current Completion System

**File:** `/home/user/dotrun/core/shared/dotrun/shell/zsh/dr_completion.zsh`

Command arrays define available completions:

| Array                  | Lines   | Current Commands                              |
| ---------------------- | ------- | --------------------------------------------- |
| `script_commands`      | 153-158 | set, move, rename, help                       |
| `aliases_commands`     | 161-165 | set, list, remove                             |
| `config_commands`      | 168-172 | set, list, remove                             |
| `collections_commands` | 175-182 | set, list, sync, update, list:details, remove |

---

## Technical Decisions

### Decision 1: Command Removal Strategy

**Objective:** Safely remove deprecated commands: `edit`, `init` (scripts), `rename`, `reload` (features), `sync`

#### Scripts Namespace Removals

**Changes to `/home/user/dotrun/core/shared/dotrun/dr`:**

1. **Remove `edit)` case blocks:**
   - Lines 533-540 (within `-s|scripts` namespace)
   - Lines 593-599 (direct `edit)` case)
2. **Keep `rename` as alias to `move`:**
   - Line 541: `move|rename)` stays BUT
   - Remove from completion (user guidance toward `move`)
3. **Remove from `script_commands` array:**
   - Remove: `'rename:Move/rename a script (alias for move)'`

#### Aliases/Configs Removals

1. **Remove `reload` from aliases:** Lines 977-979
2. **Update help text:** Remove references to removed commands

### Decision 2: Default Behavior Implementation

**Objective:** Make Aliases/Configs use ADD/EDIT as default action

#### Current Flow (Aliases)

```bash
-a|aliases)
  case "${2:-}" in
    init) ... ;;
    set) ... ;;
    list) ... ;;
    remove|rm) ... ;;
    *) # Shows error or help
  esac
```

#### New Flow (Aliases)

```bash
-a|aliases)
  # Handle list flags first
  if [[ "${2:-}" == "-l" || "${2:-}" == "-L" ]]; then
    # New list implementation
    list_files "aliases" ...
    exit 0
  fi

  case "${2:-}" in
    init) ... ;;
    set) ... ;;       # Keep for backwards compat
    move) ... ;;      # NEW
    rm) ... ;;        # Renamed from remove
    help) ... ;;      # NEW
    "") # Show help
      show_aliases_help
      ;;
    -*)  # Unknown flag
      echo "Error: Unknown flag ${2}"
      ;;
    *)   # DEFAULT: Treat as filename -> edit
      aliases_set "$2"  # Reuse set logic
      ;;
  esac
```

### Decision 3: rm Command Implementation

**Objective:** Add script deletion with `dr rm` and `dr -s rm`

#### New Function

```bash
# Remove/delete a script
# Location: After move_script() function (~line 495)
remove_script() {
  local name="$1"
  validate_script_name "$name" || exit 1

  local file
  file=$(find_script_file "$name")
  [[ -z "$file" ]] && {
    echo "Error: Script '$name' not found" >&2
    exit 1
  }

  local rel_path="${file#"$BIN_DIR"/}"

  # Colored confirmation
  echo -e "${YELLOW}⚠️  Remove script:${RESET} ${CYAN}$rel_path${RESET}"
  read -p "Are you sure? [y/N] " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm "$file" && {
      echo -e "${GREEN}✓ Removed:${RESET} $rel_path"
      # Clean up empty directories
      cleanup_empty_dirs "$(dirname "$file")"
    }
  else
    echo "Cancelled"
  fi
}
```

#### Case Handlers

```bash
# In scripts namespace (after help case)
remove|rm)
  [[ -z "${3:-}" ]] && { echo "Usage: dr $1 rm <name>"; exit 1; }
  remove_script "$3"
  ;;

# At root level (after help case)
remove|rm)
  [[ -z "${2:-}" ]] && { echo "Usage: dr rm <name>"; exit 1; }
  remove_script "$2"
  ;;
```

### Decision 4: List Commands (-l/-L) for Aliases/Configs

**Objective:** Add tree-style listing matching scripts behavior

#### Generic List Function

```bash
# Generalized tree listing
# list_feature_files feature_type base_dir extension show_docs [scope]
list_feature_files() {
  local feature_type="$1" # "aliases" or "configs"
  local base_dir="$2"
  local extension="$3" # ".aliases" or ".config"
  local show_docs="$4" # 0=short, 1=long
  local scope="${5:-}"

  # Reuse logic from existing list_scripts()
  # Replace hardcoded values with parameters
  # Use feature-specific colors/icons
}
```

#### Integration Points

**Aliases:** Before `case "${2:-}"` block

```bash
-a|aliases)
  if [[ "${2:-}" == "-l" ]]; then
    list_feature_files "aliases" "$ALIASES_DIR" ".aliases" 0 "${3:-}"
    exit 0
  elif [[ "${2:-}" == "-L" ]]; then
    list_feature_files "aliases" "$ALIASES_DIR" ".aliases" 1 "${3:-}"
    exit 0
  fi
  # ... rest of case
```

**Configs:** Same pattern with `$CONFIG_DIR` and `.config`

### Decision 5: Global Reload Command

**Objective:** Feature-agnostic reload that sources ~/.drrc

#### Implementation

```bash
# At top of main case statement (before -l|-L)
-r|reload)
  local drrc="$HOME/.drrc"
  if [[ ! -f "$drrc" ]]; then
    echo "Error: ~/.drrc not found" >&2
    exit 1
  fi

  echo -e "${CYAN}🔄 Reloading DotRun...${RESET}"
  echo ""
  echo "Run this in your current shell:"
  echo -e "  ${GREEN}source ~/.drrc${RESET}"
  echo ""
  echo "Or add an alias:"
  echo -e "  ${GREEN}alias drr='source ~/.drrc'${RESET}"
  ;;
```

**Note:** Cannot source in subshell - must provide instructions.

### Decision 6: Completion System Updates

**Objective:** Update arrays and handlers for new command structure

#### Array Updates

**script_commands (final):**

```zsh
script_commands=(
  'set:Create or open a script in editor'
  'move:Move/rename a script'
  'rm:Remove a script'
  'help:Show script documentation'
)
```

**aliases_commands (final):**

```zsh
aliases_commands=(
  'move:Move/rename an alias file'
  'rm:Remove an alias file'
  'help:Show alias documentation'
  'init:Initialize aliases folder'
  '-l:List aliases (short)'
  '-L:List aliases (long)'
)
```

**config_commands (final):**

```zsh
config_commands=(
  'move:Move/rename a config file'
  'rm:Remove a config file'
  'help:Show config documentation'
  'init:Initialize configs folder'
  '-l:List configs (short)'
  '-L:List configs (long)'
)
```

#### Hint Updates

**`_dr_show_hint()` modification:**

```zsh
_dr_show_hint() {
  local hint="(hint: set, move, rm, help, -l, -L)"
  compadd -x "${hint}"
}
```

#### Default Behavior Completion

For `-a` and `-c` namespaces, show both commands AND files:

```zsh
-a|aliases)
  # Show both commands and files for default behavior
  _dr_add_commands_with_tag 'aliases-commands' "${aliases_commands[@]}"
  _dr_get_feature_context aliases "" | _dr_display_feature_context aliases ""
  ;;
```

---

## File Modification Summary

### `/home/user/dotrun/core/shared/dotrun/dr`

| Section           | Lines     | Changes                                       |
| ----------------- | --------- | --------------------------------------------- |
| Scripts namespace | 523-584   | Remove edit, add rm case                      |
| Direct commands   | 586-626   | Remove edit, add rm case                      |
| Global commands   | ~516      | Add reload handler                            |
| Aliases namespace | 935-1001  | Add -l/-L, move, help, rm; remove reload      |
| Configs namespace | 1003-1059 | Add -l/-L, move, help, rm                     |
| Help outputs      | Various   | Update all help text                          |
| New functions     | ~495      | Add `remove_script()`, `list_feature_files()` |

**Estimated changes:** +200 lines (new features), -50 lines (removals)

### `/home/user/dotrun/core/shared/dotrun/shell/zsh/dr_completion.zsh`

| Section            | Lines            | Changes             |
| ------------------ | ---------------- | ------------------- |
| Command arrays     | 153-182          | Update all arrays   |
| Hint function      | 218-220          | Update hint text    |
| Scripts completion | 630-716          | Remove edit, add rm |
| Aliases completion | 649-652, 798-829 | Add new commands    |
| Configs completion | 654-657, 831-867 | Add new commands    |

**Estimated changes:** +100 lines

---

## Testing Strategy

### Unit Tests (Manual)

**Phase 1 - Scripts:**

```bash
# Positive tests
dr test-script      # Should run
dr set test-script  # Should open editor
dr move old new     # Should move with preview
dr rm test-script   # Should delete with confirm
dr help test-script # Should show docs
dr -l               # Should list short
dr -L               # Should list long

# Negative tests
dr edit test-script # Should fail gracefully
dr init test-script # Should fail gracefully
dr rename old new   # Should suggest move
```

**Phase 2 - Aliases:**

```bash
# Positive tests
dr -a my-alias      # Should open editor (default)
dr -a move old new  # Should move with preview
dr -a rm my-alias   # Should delete
dr -a help my-alias # Should show docs
dr -a -l            # Should list short
dr -a -L            # Should list long
dr -a init          # Should init folders
```

**Phase 3 - Configs:**

```bash
# Same tests as aliases with -c flag
```

**Phase 4 - Global:**

```bash
dr reload # Should show instructions
```

### Integration Tests

1. TAB completion in fresh shell
2. Help output verification
3. Cross-feature consistency check

---

## Risks and Mitigations

| Risk                       | Impact | Mitigation                             |
| -------------------------- | ------ | -------------------------------------- |
| Breaking user workflows    | High   | Document migration, keep `set` working |
| Completion confusion       | Medium | Clear hint messages, test thoroughly   |
| Default behavior surprises | Medium | Document clearly in help and CHANGELOG |
| Shell compatibility        | Low    | Test bash/zsh/fish completion          |

---

## Success Criteria

1. All commands from `featuresCommandOverview.md` work as specified
2. No references to removed commands remain
3. TAB completion shows only valid commands
4. Help text matches implementation exactly
5. `-s`/`-a`/`-c` variants identical to non-flag versions

---

**End of Design Document**
