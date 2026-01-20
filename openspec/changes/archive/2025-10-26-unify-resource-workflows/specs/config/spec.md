# Configuration Management - Delta Spec

## ADDED Requirements

### Requirement: File-Based Config Management

The system SHALL provide a file-based workflow for creating and managing environment configuration. Users SHALL create config files containing multiple export statements that are sourced by their shell.

#### Scenario: Create new config file

- **WHEN** user runs `dr config set <filename>`
- **THEN** system opens `~/.config/dotrun/configs/<filename>.config` in EDITOR
- **AND** file contains skeleton with documentation and examples
- **AND** file is created if it doesn't exist

#### Scenario: Edit existing config file

- **WHEN** user runs `dr config set <filename>` for existing file
- **THEN** system opens existing file in EDITOR
- **AND** user can modify config variables directly in editor

#### Scenario: Category organization

- **WHEN** user runs `dr config set api/keys`
- **THEN** system creates `~/.config/dotrun/configs/api/` directory
- **AND** opens `~/.config/dotrun/configs/api/keys.config` in EDITOR
- **AND** category folder structure is preserved

### Requirement: Config File Format

Config files SHALL use standard bash export syntax with one export per line. Files SHALL be executable bash scripts that can be sourced by the shell.

#### Scenario: Multi-export file structure

- **WHEN** user creates config file with skeleton
- **THEN** file contains:

  ```bash
  #!/usr/bin/env bash
  # DotRun Config File
  # Examples and documentation
  
  # User-defined exports:
  export API_KEY="value"
  export DB_HOST="localhost"
  export NODE_ENV="development"
  ```

#### Scenario: File sourcing

- **WHEN** shell sources config file
- **THEN** all exported variables become available in environment
- **AND** variables can be accessed via `$VAR_NAME`

### Requirement: Config File Listing

The system SHALL provide commands to list all config files with metadata showing the number of exports defined in each file.

#### Scenario: List all config files

- **WHEN** user runs `dr config list`
- **THEN** system displays all `.config` files
- **AND** shows relative path for each file
- **AND** shows count of exports defined in each file
- **FORMAT** `<path> (<count> exports defined)`

#### Scenario: List with categories

- **WHEN** user runs `dr config list --categories`
- **THEN** system shows category information for each file
- **FORMAT** `<path> [<category>]`

#### Scenario: Filter by category

- **WHEN** user runs `dr config list --category api`
- **THEN** system shows only files in api category
- **AND** excludes files from other categories

### Requirement: Config File Removal

The system SHALL allow users to remove config files with confirmation and automatic cleanup of empty directories.

#### Scenario: Remove config file

- **WHEN** user runs `dr config remove <filename>`
- **THEN** system prompts for confirmation
- **AND** removes file if user confirms
- **AND** removes empty parent directories automatically

#### Scenario: Cancel removal

- **WHEN** user runs `dr config remove <filename>`
- **AND** user declines confirmation
- **THEN** system cancels operation
- **AND** file remains unchanged

### Requirement: Editor Validation

The system SHALL validate that EDITOR environment variable is set and points to a valid executable before opening files for editing.

#### Scenario: Missing EDITOR

- **WHEN** user runs `dr config set <filename>`
- **AND** EDITOR environment variable is not set
- **THEN** system shows error: "EDITOR environment variable is not set"
- **AND** provides instruction to set EDITOR
- **AND** does not open editor

#### Scenario: Invalid EDITOR

- **WHEN** user runs `dr config set <filename>`
- **AND** EDITOR points to non-existent executable
- **THEN** system shows error: "Editor '<name>' not found in PATH"
- **AND** does not attempt to open editor

## MODIFIED Requirements

_Note: No existing requirements modified - this is new functionality_

## REMOVED Requirements

_Note: No requirements removed_

## Future Requirements (Not Yet Implemented)

### Requirement: Secure Value Masking (PLANNED)

The system SHOULD support marking sensitive configuration values with `# SECURE` comments and masking them in list output.

#### Scenario: Mark value as secure (PLANNED)

- **WHEN** user adds `# SECURE` comment above an export
- **THEN** system detects the marker when listing configs
- **AND** masks the value in output as `****`

#### Scenario: Show secure value (PLANNED)

- **WHEN** user runs `dr config get <key> --show-value`
- **THEN** system shows actual value even if marked secure
- **AND** warns that value is sensitive

**Implementation Status:** Not yet implemented. Currently no secure value masking exists.
