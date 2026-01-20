# Redesign Collections System

## Why

The current collections system lacks proper version management, update tracking, and modification detection. Users struggle with:

- No way to update imported resources when collections change
- No tracking of which files came from which collection
- No detection of user modifications during updates
- No conflict resolution when updates overlap with local changes
- Unclear ownership between collection files and user files

A better system is needed that maintains persistent collection clones, tracks imported resources with version control, detects user modifications, and provides safe update workflows.

## What Changes

- **Persistent collection storage** in `$DR_CONFIG/collections/{name}/` as pristine git clones
- **Copy-based imports** with SHA256 hash tracking for modification detection
- **Version management** via git tags with `dr -col sync` and `dr -col update`
- **Conflict resolution** for files modified both locally and in collection updates
- **Collection metadata** via `dotrun.collection.yml` (name, version, description, author, repo)
- **Enhanced commands**:
  - `dr -col init` - Create collection structure (for authors)
  - `dr -col add <url>` - Install collection and import resources
  - `dr -col list` - Show installed collections with versions
  - `dr -col sync` - Check all collections for updates
  - `dr -col update <name>` - Update collection with conflict resolution
  - `dr -col remove <name>` - Remove collection tracking
  - `dr -col` - Interactive resource browser

## Impact

- **Affected specs:**
  - `collections` - Complete redesign with copy-based architecture and version tracking

- **Affected code:**
  - `core/shared/dotrun/core/collections.sh` - Complete rewrite with copy-based imports and hash tracking (NEW location: `~/.local/share/dotrun/core/collections.sh`)
  - `core/shared/dotrun/dr` - New command routing for `-col` flag and `collections` subcommand
  - New `dotrun.collection.yml` metadata file format
  - Tracking database: `~/.local/share/dotrun/collections.conf`
  - Directory structure: New `core/` folder in tool files for system logic modules

- **Breaking changes:**
  - **BREAKING**: Old `dr import <url> <name>` command removed
  - **BREAKING**: Old `dr export <name> <path>` command removed
  - **BREAKING**: Old metadata format (`.dr-collection.yml`) replaced with `dotrun.collection.yml`
  - **BREAKING**: Collections now stored in `$DR_CONFIG/collections/` as persistent git clones
  - **BREAKING**: `dr collections list` shows installed collections with version info (not just URLs)
  - **BREAKING**: Import now creates copies (not symlinks) with hash tracking

- **New features:**
  - ✨ Version tracking and update detection via git tags
  - ✨ SHA256 hash-based modification detection
  - ✨ Interactive conflict resolution during updates
  - ✨ 3-way merge support for modified files
  - ✨ Partial imports and granular updates
  - ✨ `dr -col init` for collection authors
  - ✨ `dr -col sync` and `dr -col update` workflows

- **Migration notes:**
  - Existing collections in `~/.config/dotrun/collections/` will be incompatible
  - Users should back up custom scripts before migration
  - Imported resources remain usable (now owned by user)
  - Re-add collections with `dr -col add <url>` to enable update tracking
  - No automated migration from old system
