# Aliases Management - Delta Spec

## ADDED Requirements

### Requirement: File-Based Alias Management

The system SHALL provide a file-based workflow for creating and managing shell aliases. Users SHALL create alias files containing multiple alias definitions that are sourced by their shell.

#### Scenario: Create new alias file

- **WHEN** user runs `dr aliases set <filename>`
- **THEN** system opens `~/.config/dotrun/aliases/<filename>.aliases` in EDITOR
- **AND** file contains skeleton with documentation and examples
- **AND** file is created if it doesn't exist

#### Scenario: Edit existing alias file

- **WHEN** user runs `dr aliases set <filename>` for existing file
- **THEN** system opens existing file in EDITOR
- **AND** user can modify aliases directly in editor

#### Scenario: Category organization

- **WHEN** user runs `dr aliases set git/shortcuts`
- **THEN** system creates `~/.config/dotrun/aliases/git/` directory
- **AND** opens `~/.config/dotrun/aliases/git/shortcuts.aliases` in EDITOR
- **AND** category folder structure is preserved

### Requirement: Alias File Format

Alias files SHALL use standard bash alias syntax with one alias per line. Files SHALL be executable bash scripts that can be sourced by the shell.

#### Scenario: Multi-alias file structure

- **WHEN** user creates alias file with skeleton
- **THEN** file contains:

  ```bash
  #!/usr/bin/env bash
  # DotRun Aliases File
  # Examples and documentation
  
  # User-defined aliases:
  alias gs='git status'
  alias gc='git commit'
  alias gp='git push'
  ```

#### Scenario: File sourcing

- **WHEN** shell sources alias file
- **THEN** all aliases in file become available in current shell
- **AND** aliases can be invoked by their defined names

### Requirement: Alias File Listing

The system SHALL provide commands to list all alias files with metadata showing the number of aliases defined in each file.

#### Scenario: List all alias files

- **WHEN** user runs `dr aliases list`
- **THEN** system displays all `.aliases` files
- **AND** shows relative path for each file
- **AND** shows count of aliases defined in each file
- **FORMAT** `<path> (<count> aliases defined)`

#### Scenario: List with categories

- **WHEN** user runs `dr aliases list --categories`
- **THEN** system shows category information for each file
- **FORMAT** `<path> [<category>]`

#### Scenario: Filter by category

- **WHEN** user runs `dr aliases list --category git`
- **THEN** system shows only files in git category
- **AND** excludes files from other categories

### Requirement: Alias File Removal

The system SHALL allow users to remove alias files with confirmation and automatic cleanup of empty directories.

#### Scenario: Remove alias file

- **WHEN** user runs `dr aliases remove <filename>`
- **THEN** system prompts for confirmation
- **AND** removes file if user confirms
- **AND** removes empty parent directories automatically

#### Scenario: Cancel removal

- **WHEN** user runs `dr aliases remove <filename>`
- **AND** user declines confirmation
- **THEN** system cancels operation
- **AND** file remains unchanged

### Requirement: Editor Validation

The system SHALL validate that EDITOR environment variable is set and points to a valid executable before opening files for editing.

#### Scenario: Missing EDITOR

- **WHEN** user runs `dr aliases set <filename>`
- **AND** EDITOR environment variable is not set
- **THEN** system shows error: "EDITOR environment variable is not set"
- **AND** provides instruction to set EDITOR
- **AND** does not open editor

#### Scenario: Invalid EDITOR

- **WHEN** user runs `dr aliases set <filename>`
- **AND** EDITOR points to non-existent executable
- **THEN** system shows error: "Editor '<name>' not found in PATH"
- **AND** does not attempt to open editor

### Requirement: Alias Reload

The system SHALL provide a command to reload alias files in the current shell without restarting.

#### Scenario: Reload aliases

- **WHEN** user runs `dr aliases reload`
- **THEN** system detects current shell (bash/zsh/fish)
- **AND** sources appropriate shell-specific loader
- **AND** all alias files are re-sourced
- **AND** new/modified aliases become available immediately

#### Scenario: Unknown shell

- **WHEN** user runs `dr aliases reload`
- **AND** shell is not bash/zsh/fish
- **THEN** system shows error: "Unknown shell"
- **AND** provides troubleshooting information

### Requirement: Alias System Initialization

The system SHALL provide initialization command that creates the aliases directory structure.

#### Scenario: Initialize aliases

- **WHEN** user runs `dr aliases init`
- **THEN** system creates `~/.config/dotrun/aliases/` directory
- **AND** shows success message
- **AND** provides usage examples
