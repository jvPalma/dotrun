# collections Specification

## Purpose

TBD - created by archiving change redesign-collections-system. Update Purpose after archive.

## Requirements

### Requirement: Collection Metadata File

Collections SHALL use a `dotrun.collection.yml` file for metadata and version tracking.

#### Scenario: Metadata file location

- **WHEN** a collection repository is created
- **THEN** it SHALL contain `dotrun.collection.yml` in the repository root
- **AND** the file SHALL use YAML format
- **AND** the file SHALL be version-controlled with the collection

#### Scenario: Required metadata fields

- **WHEN** parsing collection metadata
- **THEN** the following fields SHALL be required:
  - `name` - Unique identifier for the collection (string, alphanumeric with hyphens)
  - `version` - Semantic version number (string, semver format: X.Y.Z)
  - `description` - Brief description of collection purpose (string)
  - `author` - Collection creator name (string)
  - `repository` - Git repository URL (string, HTTPS format)

#### Scenario: Optional metadata fields

- **WHEN** parsing collection metadata
- **THEN** the following fields MAY be present:
  - `license` - License identifier (string, e.g., "MIT", "Apache-2.0")
  - `homepage` - Documentation or website URL (string)
  - `dependencies` - List of other required collections (array of strings)

### Requirement: Collection Initialization

Collection authors SHALL use `dr -col init` to create collection structure.

#### Scenario: Initialize collection structure

- **WHEN** user runs `dr -col init` in an empty directory
- **THEN** it SHALL create `dotrun.collection.yml` with template content
- **AND** it SHALL create empty directories: `scripts/`, `aliases/`, `helpers/`, `configs/`
- **AND** it SHALL use directory name as default collection name
- **AND** it SHALL set version to "0.1.0" by default
- **AND** it SHALL prompt user for description and author

#### Scenario: Initialize in existing directory

- **WHEN** user runs `dr -col init` in directory with existing files
- **THEN** it SHALL only create `dotrun.collection.yml` if it doesn't exist
- **AND** it SHALL create missing resource directories
- **AND** it SHALL preserve existing files
- **AND** it SHALL warn if `dotrun.collection.yml` already exists

### Requirement: Persistent Collection Storage

Collections SHALL be stored as persistent git clones in user configuration directory.

#### Scenario: Collection storage location

- **WHEN** a collection is added
- **THEN** it SHALL be cloned to `$DR_CONFIG/collections/{name}/`
- **AND** `{name}` SHALL be the value from `dotrun.collection.yml`
- **AND** the clone SHALL be a full git repository (not shallow)
- **AND** the directory SHALL remain even after resources are imported

#### Scenario: Collection directory structure

- **WHEN** viewing collection storage
- **THEN** structure SHALL be:
  ```
  $DR_CONFIG/collections/
  ├── collection-name-1/
  │   ├── .git/
  │   ├── dotrun.collection.yml
  │   ├── scripts/
  │   ├── aliases/
  │   ├── helpers/
  │   └── configs/
  └── collection-name-2/
      └── ...
  ```

### Requirement: Collections Tool Module

The collections system SHALL be implemented as a core tool module.

#### Scenario: Tool module location

- **WHEN** collections functionality is provided
- **THEN** implementation SHALL be in `~/.local/share/dotrun/core/collections.sh`
- **AND** file SHALL contain all collections system logic (2000+ lines)
- **AND** file SHALL be sourced by `dr` binary when collections commands are used
- **AND** file SHALL NOT be placed in user config directory
- **AND** file SHALL be part of tool files, not user-modifiable content

#### Scenario: Module organization

- **WHEN** organizing tool files
- **THEN** structure SHALL be:
  ```
  ~/.local/share/dotrun/
  ├── dr                          # Main binary
  ├── .dr_config_loader           # Shell detection
  ├── core/
  │   └── collections.sh          # Collections system (NEW)
  └── shell/
      ├── bash/
      ├── zsh/
      └── fish/
  ```
- **AND** core/ directory SHALL contain tool logic modules
- **AND** core/ SHALL be separate from shell-specific files

### Requirement: Collections Tracking Database

The system SHALL maintain a tracking database at `~/.local/share/dotrun/collections.conf`.

#### Scenario: Tracking file location

- **WHEN** collections are managed
- **THEN** tracking data SHALL be stored in `~/.local/share/dotrun/collections.conf`
- **AND** the file SHALL use INI format
- **AND** the file SHALL be created automatically if it doesn't exist
- **AND** tool files directory SHALL be used (not user config directory)

#### Scenario: Tracking file format

- **WHEN** a collection is installed
- **THEN** tracking file SHALL contain section `[collection-name]`
- **AND** section SHALL include:
  - `url` - Git repository URL
  - `version` - Currently installed version
  - `path` - Absolute path to collection directory
  - `imported_scripts` - Comma-separated list of `filename:hash` pairs
  - `imported_aliases` - Comma-separated list of `filename:hash` pairs
  - `imported_helpers` - Comma-separated list of `filename:hash` pairs
  - `imported_configs` - Comma-separated list of `filename:hash` pairs

#### Scenario: Hash format

- **WHEN** storing file hashes
- **THEN** hash SHALL be SHA256 of file content
- **AND** hash SHALL be truncated to first 8 characters for storage
- **AND** hash SHALL be used to detect user modifications

### Requirement: Add Collection Command

Users SHALL use `dr -col add <url>` to install collections.

#### Scenario: Add collection with valid URL

- **WHEN** user runs `dr -col add https://github.com/user/repo.git`
- **THEN** it SHALL validate GitHub URL format
- **AND** it SHALL clone repository to temporary location
- **AND** it SHALL read `dotrun.collection.yml` to extract name and version
- **AND** it SHALL check for name conflicts in collections.conf
- **AND** it SHALL clone repository to `$DR_CONFIG/collections/{name}/`
- **AND** it SHALL display interactive resource selection menu
- **AND** it SHALL import selected resources as copies
- **AND** it SHALL calculate SHA256 hash of each imported file
- **AND** it SHALL update collections.conf with tracking information

#### Scenario: Collection name conflict

- **WHEN** adding collection with name that already exists
- **THEN** it SHALL error with message: "Collection '{name}' already exists"
- **AND** it SHALL show existing collection URL
- **AND** it SHALL suggest using `dr -col list` to view installed collections
- **AND** operation SHALL be aborted

#### Scenario: Invalid or missing metadata

- **WHEN** repository lacks `dotrun.collection.yml` or has invalid format
- **THEN** it SHALL error with message: "Invalid collection: missing or malformed dotrun.collection.yml"
- **AND** it SHALL list required fields
- **AND** operation SHALL be aborted

### Requirement: List Collections Command

Users SHALL use `dr -col list` to view installed collections.

#### Scenario: List installed collections

- **WHEN** user runs `dr -col list`
- **THEN** it SHALL read all sections from collections.conf
- **AND** it SHALL display numbered list of collections
- **AND** for each collection it SHALL show:
  - Collection name
  - Currently installed version
  - Repository URL
  - Count of imported resources by type (scripts, aliases, helpers, configs)
- **AND** it SHALL display "No collections installed" if none exist

#### Scenario: List output format

- **WHEN** displaying collection list
- **THEN** format SHALL be:

  ```
  Installed Collections:

  1. my-scripts (v1.0.0)
     URL: https://github.com/user/my-scripts.git
     Imported: 2 scripts, 1 alias

  2. devtools (v2.3.0)
     URL: https://github.com/org/devtools.git
     Imported: 5 scripts, 3 aliases, 2 helpers
  ```

### Requirement: Sync Collections Command

Users SHALL use `dr -col sync` to check for updates.

#### Scenario: Check all collections for updates

- **WHEN** user runs `dr -col sync`
- **THEN** it SHALL iterate through all collections in collections.conf
- **AND** for each collection it SHALL:
  - Change to collection directory
  - Run `git fetch origin`
  - List available tags
  - Compare current version with latest tag
  - Mark as "update available" if newer version exists
- **AND** it SHALL display summary of updates available
- **AND** it SHALL suggest running `dr -col update <name>` for each collection with updates

#### Scenario: Sync output with updates available

- **WHEN** updates are detected
- **THEN** output SHALL show:

  ```
  Checking for updates...

  my-scripts: 1.0.0 → 1.1.0 available
    Modified files:
      - scripts/deploy.sh
    New files:
      - scripts/monitoring.sh

  devtools: up to date (v2.3.0)

  Run 'dr -col update <name>' to update specific collection
  ```

### Requirement: Update Collection Command

Users SHALL use `dr -col update <name>` to update collections with conflict resolution.

#### Scenario: Update collection to latest version

- **WHEN** user runs `dr -col update my-scripts`
- **THEN** it SHALL change to collection directory
- **AND** it SHALL run `git fetch origin`
- **AND** it SHALL checkout latest version tag
- **AND** it SHALL read new version from dotrun.collection.yml
- **AND** it SHALL compare each previously imported file:
  - Calculate hash of current user file
  - Compare with stored original hash
  - If hashes match: file is unmodified, safe to update
  - If hashes differ: file was modified, conflict resolution needed
- **AND** it SHALL list new files available in collection
- **AND** it SHALL present interactive prompts for each file
- **AND** it SHALL update collections.conf with new version and hashes

#### Scenario: Update unmodified file

- **WHEN** imported file has not been modified by user
- **THEN** prompt SHALL be:
  ```
  deploy.sh: UNMODIFIED
    [U]pdate  [D]iff  [S]kip: _
  ```
- **AND** selecting Update SHALL overwrite user file with collection version
- **AND** selecting Diff SHALL show changes between versions
- **AND** selecting Skip SHALL leave user file unchanged

#### Scenario: Update modified file

- **WHEN** imported file was modified by user
- **THEN** prompt SHALL be:

  ```
  deploy.sh: ⚠️  LOCAL CHANGES DETECTED
    Collection version: 1.0.0 → 1.1.0
    Your version: Modified locally

    [K]eep yours (skip update)
    [O]verwrite with collection version
    [D]iff (show changes)
    [M]erge (3-way if possible)
    [B]ackup yours, then overwrite

    Choice: _
  ```

- **AND** Keep SHALL preserve user file, skip update
- **AND** Overwrite SHALL replace with collection version (losing user changes)
- **AND** Diff SHALL show 3 versions: original, user's, collection's
- **AND** Merge SHALL attempt 3-way merge using git merge-file
- **AND** Backup SHALL save user file as `.bak`, then overwrite

#### Scenario: Import new file from update

- **WHEN** collection added new files since last version
- **THEN** prompt SHALL be:
  ```
  monitoring.sh: NEW FILE
    [I]mport  [V]iew  [S]kip: _
  ```
- **AND** Import SHALL copy file to user directory
- **AND** View SHALL display file contents
- **AND** Skip SHALL not import file

### Requirement: Remove Collection Command

Users SHALL use `dr -col remove <name>` to remove collection tracking.

#### Scenario: Remove collection

- **WHEN** user runs `dr -col remove my-scripts`
- **THEN** it SHALL display warning:

  ```
  This will remove tracking for 'my-scripts'
  Imported files will remain in:
    - $DR_CONFIG/scripts/deploy.sh
    - $DR_CONFIG/scripts/backup.sh
    - $DR_CONFIG/aliases/git.aliases

  Continue? [y/N]
  ```

- **AND** if confirmed, it SHALL remove collection directory
- **AND** it SHALL remove section from collections.conf
- **AND** it SHALL NOT delete imported files (they are user-owned)
- **AND** it SHALL display "Imported files kept. Delete manually if unwanted."

### Requirement: Interactive Collection Browser

Users SHALL use `dr -col` to interactively browse and import resources.

#### Scenario: Interactive browser workflow

- **WHEN** user runs `dr -col` with no arguments
- **THEN** it SHALL display installed collections with numbered list
- **AND** it SHALL show which collections have updates available
- **AND** it SHALL allow selection of collection to browse
- **AND** after selection, it SHALL show resource type menu
- **AND** after type selection, it SHALL show specific resources to import
- **AND** it SHALL follow same import workflow as `dr -col add`

### Requirement: Copy-Based Resource Import

Imported resources SHALL be copied to user directories, not symlinked.

#### Scenario: Import script file

- **WHEN** importing a script from collection
- **THEN** source SHALL be `$DR_CONFIG/collections/{name}/scripts/{file}.sh`
- **AND** destination SHALL be `$DR_CONFIG/scripts/{file}.sh`
- **AND** file SHALL be copied (not symlinked)
- **AND** file SHALL be made executable (chmod +x)
- **AND** subdirectory structure SHALL be preserved if present
- **AND** SHA256 hash of copied file SHALL be calculated and stored

#### Scenario: Import alias file

- **WHEN** importing alias from collection
- **THEN** source SHALL be `$DR_CONFIG/collections/{name}/aliases/{file}`
- **AND** destination SHALL be `$DR_CONFIG/aliases/{file}`
- **AND** file SHALL be copied (not symlinked)
- **AND** SHA256 hash SHALL be stored

#### Scenario: Import helper file

- **WHEN** importing helper from collection
- **THEN** source SHALL be `$DR_CONFIG/collections/{name}/helpers/{file}`
- **AND** destination SHALL be `$DR_CONFIG/helpers/{file}`
- **AND** file SHALL be copied (not symlinked)
- **AND** SHA256 hash SHALL be stored

#### Scenario: Import config file

- **WHEN** importing config from collection
- **THEN** source SHALL be `$DR_CONFIG/collections/{name}/configs/{file}`
- **AND** destination SHALL be `$DR_CONFIG/configs/{file}`
- **AND** file SHALL be copied (not symlinked)
- **AND** SHA256 hash SHALL be stored

#### Scenario: Preserve subdirectory structure

- **WHEN** collection has nested structure like `scripts/git/deploy.sh`
- **THEN** import destination SHALL be `$DR_CONFIG/scripts/git/deploy.sh`
- **AND** intermediate directories SHALL be created as needed
- **AND** subdirectory structure SHALL match collection layout

### Requirement: Import Conflict Resolution

The system SHALL handle name conflicts during import.

#### Scenario: File already exists during import

- **WHEN** importing file that already exists in destination
- **THEN** user SHALL be prompted:
  ```
  deploy.sh already exists in $DR_CONFIG/scripts/
  [O]verwrite  [R]ename  [S]kip: _
  ```
- **AND** Overwrite SHALL replace existing file
- **AND** Rename SHALL save as `deploy-1.sh` (incrementing number until unique)
- **AND** Skip SHALL cancel import of that file only

### Requirement: Hash-Based Modification Detection

The system SHALL use SHA256 hashes to detect file modifications.

#### Scenario: Calculate file hash

- **WHEN** importing or updating a file
- **THEN** hash SHALL be calculated using SHA256 algorithm
- **AND** hash SHALL be based on file content only (not metadata)
- **AND** hash SHALL be truncated to first 8 hex characters
- **AND** format SHALL be: `filename:hash` in tracking file

#### Scenario: Detect user modifications

- **WHEN** checking if user modified an imported file
- **THEN** current file hash SHALL be calculated
- **AND** current hash SHALL be compared with stored original hash
- **AND** if hashes match: file is unmodified
- **AND** if hashes differ: file was modified by user
- **AND** modification status SHALL affect update behavior

### Requirement: Version Tag Validation

Collections SHALL use git tags for version tracking.

#### Scenario: Parse version from git tags

- **WHEN** checking collection version
- **THEN** system SHALL list git tags matching pattern `v*.*.*`
- **AND** system SHALL extract semantic version from tags
- **AND** system SHALL compare versions numerically (not lexically)
- **AND** highest version SHALL be considered "latest"

#### Scenario: Version tag format

- **WHEN** collection author tags releases
- **THEN** tags SHOULD follow format: `vX.Y.Z` (e.g., `v1.0.0`)
- **AND** version in tag SHALL match version in dotrun.collection.yml
- **AND** system SHALL handle tags with or without 'v' prefix
