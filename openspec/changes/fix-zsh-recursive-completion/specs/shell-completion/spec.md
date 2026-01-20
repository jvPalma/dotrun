# shell-completion Specification

## Purpose

Define the behavior of shell tab completion for the `dr` command across supported shells (bash, zsh, fish). This spec focuses on ZSH-specific requirements being added or modified.

## ADDED Requirements

### Requirement: Recursive Script Search at Root Level

When typing a partial script name at root level (`dr <pattern><TAB>`), the completion SHALL show all matching scripts across all nested folders.

#### Scenario: Partial name matches multiple scripts in different folders

- **GIVEN** scripts exist at:
  - `~/.config/dotrun/scripts/folder1/tab-testing.sh`
  - `~/.config/dotrun/scripts/folder1/folder2/folder3/tab-testing.sh`
- **WHEN** user types `dr tab-t<TAB>` at root level
- **THEN** completion SHALL show both scripts with full relative paths:
  - `folder1/tab-testing`
  - `folder1/folder2/folder3/tab-testing`
- **AND** results SHALL be displayed with appropriate emoji decoration (🚀 for scripts)
- **AND** results SHALL be colored according to zstyle configuration

#### Scenario: Exact basename matches across hierarchy

- **GIVEN** multiple scripts share the same basename in different folders
- **WHEN** user types the exact basename followed by TAB
- **THEN** completion SHALL show all matching scripts from all folders
- **AND** user SHALL be able to select the desired script path

#### Scenario: Prefix matching prioritized over substring matching

- **GIVEN** scripts exist with names: `profile`, `prompt`, `deployment`
- **WHEN** user types `dr pro<TAB>`
- **THEN** prefix matches (`profile`, `prompt`) SHALL appear before substring matches
- **AND** shallower paths SHALL appear before deeper paths within each priority

#### Scenario: No matches found

- **GIVEN** no scripts match the typed pattern
- **WHEN** user types `dr nonexistent<TAB>`
- **THEN** no completions SHALL be shown
- **AND** completion function SHALL return non-zero exit status

### Requirement: No Debug Logging in Production

The ZSH completion script SHALL NOT write debug output to files in normal operation.

#### Scenario: Normal completion operation

- **WHEN** user triggers tab completion in normal operation
- **THEN** no writes SHALL occur to `/tmp/dr_completion_debug.log`
- **AND** no writes SHALL occur to any other debug log files
- **AND** completion performance SHALL not be impacted by logging overhead

#### Scenario: Debug mode enabled (optional)

- **WHEN** environment variable `DR_COMPLETION_DEBUG` is set to non-empty value
- **THEN** debug logging MAY write to `/tmp/dr_completion_debug.log`
- **AND** this behavior is optional (may be implemented in future)

### Requirement: Correct Shell Declaration

The ZSH completion script SHALL declare correct shell type for static analysis tools.

#### Scenario: Shellcheck configuration

- **WHEN** the file `dr_completion.zsh` contains a shellcheck directive
- **THEN** the directive SHALL specify `shell=zsh` (not `shell=bash`)
- **AND** the file SHALL use ZSH-specific syntax appropriately

## MODIFIED Requirements

### Requirement: Hierarchical Navigation Unchanged

Existing hierarchical folder navigation SHALL continue to work as before.

#### Scenario: Empty root level completion

- **WHEN** user types `dr <TAB>` with no pattern
- **THEN** completion SHALL show root-level folders and scripts
- **AND** a hint message SHALL be displayed showing namespace options
- **AND** folders SHALL be displayed with 📁 emoji and trailing slash

#### Scenario: Folder path completion

- **WHEN** user types `dr folder/<TAB>` (pattern ends with slash)
- **THEN** completion SHALL show contents of that folder
- **AND** subfolders SHALL be displayed with 📁 emoji
- **AND** scripts SHALL be displayed with 🚀 emoji
- **AND** recursive search SHALL NOT be triggered

#### Scenario: Namespace commands unchanged

- **WHEN** user types `dr -s <TAB>` or `dr -a <TAB>` or `dr -c <TAB>` or `dr -col <TAB>`
- **THEN** namespace-specific completions SHALL be shown
- **AND** behavior SHALL be identical to before this change

### Requirement: Return Values Consistency

Completion functions SHALL return appropriate exit codes.

#### Scenario: Successful completion with matches

- **WHEN** completion function finds and displays matches
- **THEN** function SHALL return 0 (success)

#### Scenario: No matches available

- **WHEN** completion function finds no matches for the pattern
- **THEN** function SHALL return 1 (failure/no matches)
- **AND** this return value SHALL NOT be masked by debug logging or other operations

## Related Capabilities

- **scripts** - Script management (execution, creation, organization)
- **collections** - Collection system (importing, updating)

## Implementation Notes

### ZSH compadd Flags

| Flag          | Purpose                                                  |
| ------------- | -------------------------------------------------------- |
| `-U`          | Add completions unconditionally (bypass prefix matching) |
| `-S ''`       | No suffix after completion (for folders)                 |
| `-d displays` | Use separate display strings (for emoji decoration)      |
| `-a`          | Next argument is array name                              |
| `-M spec`     | Matcher specification for path completion                |

### ZSH \_wanted Function

The `_wanted` function registers completion tags for zstyle integration:

```zsh
_wanted folders expl 'folders' compadd -U -S '' -d displays -a -- matches
```

This enables:

- Group ordering via `zstyle ':completion:*:*:dr:*' group-order`
- Color coding via `zstyle ':completion:*:*:dr:*:folders' list-colors`
