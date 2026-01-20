# Collections System Redesign

## Context

The original DotRun collections system was designed around the concept of "installing" collections as persistent entities with metadata tracking. Collections were cloned to a permanent location, metadata was parsed from `.dr-collection.yml` files, and users could list "installed" collections.

This approach created several problems:

1. **Complexity**: Metadata files, version tracking, collection state management
2. **Confusion**: Users unclear about difference between "collection" and "resources from collection"
3. **Disk Usage**: Full repository clones kept permanently
4. **Update Workflow**: No clear way to update collections once imported
5. **Discoverability**: Hard to browse collections without installing them first

### Constraints

- Must work with standard GitHub repositories (no special structure required)
- Must support bash 4.0+, zsh 5.0+, fish 3.0+
- Must be significantly simpler than original system
- Must not break existing user scripts/aliases/helpers
- Interactive menus must work in all supported shells

### Stakeholders

- **End users**: Need simple way to discover and import resources
- **Collection authors**: Need minimal requirements for sharing scripts
- **Contributors**: Need maintainable, understandable collection code

## Goals / Non-Goals

### Goals

- **Simplicity first**: Store URLs, not full collections
- **Interactive discovery**: Browse and select resources before importing
- **Temporary cache**: Clone only when needed, clean up after
- **Direct import**: Resources become user's files, no collection tracking
- **Minimal requirements**: Standard GitHub repos work out of box
- **Clear mental model**: Collections are sources, resources are what you import

### Non-Goals

- Collection versioning or update tracking
- Dependency management between collections
- Automatic updates of imported resources
- Collection metadata or description files
- Multi-repository collection support
- Non-GitHub git sources (can be added later if needed)

## Decisions

### Decision 1: URL Registry Instead of Installed Collections

**What**: Store only GitHub URLs in a simple config file, not full collection clones

**Why**:

- **Minimal disk usage**: No permanent clones
- **Simple mental model**: Collections are bookmarks, not installations
- **Easy updates**: Re-import from URL anytime
- **No orphaned data**: No stale collection metadata

**Alternatives considered**:

- Keep persistent clones → Rejected: Wastes disk, requires update management
- Use git submodules → Rejected: Too complex, git-repo-specific
- Track imported resources → Rejected: Adds unnecessary state

### Decision 2: Interactive 3-Step Selection Flow

**What**: Step 1: Pick collection → Step 2: Pick resource type → Step 3: Pick specific resources

**Why**:

- **Discoverability**: See what's available before importing
- **Selective import**: Choose only needed resources
- **Clear workflow**: One decision at a time
- **Prevents bloat**: Don't import entire collections blindly

**Alternatives considered**:

- Auto-import everything → Rejected: Clutters user directories
- CLI flags for selection → Rejected: Less discoverable, harder to use
- Web UI for browsing → Rejected: Out of scope

### Decision 3: Temporary Cache with Cleanup

**What**: Clone to cache during selection, delete after import completes

**Why**:

- **Minimal footprint**: No permanent disk usage for collections
- **Privacy**: Browsing collections doesn't leave traces
- **Simplicity**: No cache management commands needed
- **Fast**: Shallow clones are quick

**Alternatives considered**:

- Persistent cache with manual cleanup → Rejected: Requires user maintenance
- No cache (re-clone for each resource) → Rejected: Wasteful network usage
- Shared cache across sessions → Rejected: Stale data problems

### Decision 4: Direct Resource Import (No Collection Tracking)

**What**: Imported resources are copied to user directories with no metadata linking them to source collection

**Why**:

- **Ownership clarity**: Imported resources belong to user
- **Modification freedom**: Users can edit without breaking collection reference
- **No update complexity**: Re-import if you want updates
- **Simpler code**: No collection state to maintain

**Alternatives considered**:

- Track source collection → Rejected: Requires metadata, update logic
- Symlink to cache → Rejected: Cache is temporary
- Git submodules per resource → Rejected: Too heavyweight

### Decision 5: Configuration File Location

**What**: Store collections.conf in `~/.local/share/dotrun/` (tool files directory)

**Why**:

- **Follows directory reorganization**: Tool config in share, user content in config
- **System-level data**: Collection URLs are system-wide, not per-script
- **Preserved on upgrades**: Share directory is for DotRun-managed files

**Alternatives considered**:

- `~/.config/dotrun/` → Rejected: Mixed with user content
- `~/.drrc` → Rejected: Should only have shell integration
- Per-user in home → Rejected: Clutter in home directory

### Decision 6: Resource Type Directory Structure

**What**: Expect collections to have `scripts/`, `aliases/`, `helpers/`, `configs/` directories

**Why**:

- **Aligns with user directory structure**: Direct mapping to import targets
- **Follows reorganization plan**: Uses new `scripts/` naming
- **Flexible**: Not all directories required
- **Extensible**: Easy to add new resource types

**Alternatives considered**:

- Single `bin/` for everything → Rejected: Doesn't match user structure
- Metadata-defined structure → Rejected: Too complex
- Flexible mapping rules → Rejected: Confusing for users

## Risks / Trade-offs

### Risk 1: No Collection Updates

**Risk**: Users must manually re-import to get updates from collections

**Mitigation**:

- Document that collections are bookmarks, not package sources
- Make re-import workflow simple (same as initial import)
- Consider future feature: "check for updates" command

### Risk 2: No Dependency Management

**Risk**: Collections can't declare dependencies on other collections

**Mitigation**:

- Keep it simple - dependencies add significant complexity
- Collections can document dependencies in README
- Users manually import dependencies if needed
- This aligns with "collections are sources" mental model

### Risk 3: GitHub URL Only

**Risk**: Can't import from GitLab, Gitea, local git repos

**Mitigation**:

- GitHub is most common case
- Future enhancement: Support other git URLs
- URL validation can be relaxed later without breaking changes

### Trade-off: Simplicity vs Features

**Decision**: Favor simplicity over advanced features

**Reasoning**:

- Original system's complexity was a problem
- Most users need basic import/export
- Advanced features can be added later if needed
- Simple system is easier to maintain and understand

## Migration Plan

### Phase 1: Implement New System (Current)

1. Complete collections.sh rewrite with new URL-based approach
2. Update dr binary to route new collections commands
3. Test interactive workflow thoroughly

### Phase 2: Update Documentation

1. Update README with new collections workflow
2. Add migration notes to CHANGELOG
3. Update CLAUDE.md with new system details
4. Create user guide for collections

### Phase 3: Remove Old System

1. Remove old collection metadata parsing code
2. Remove `.dr-collection.yml` validation
3. Update examples/ collection to work with new system
4. Clean up dead code

### No Automated Migration

**Decision**: No automated migration from old collections system

**Reasoning**:

- Old "installed collections" concept doesn't map to new URL registry
- Imported resources still work fine (they're just files now)
- Users can re-add collection URLs manually (one-time task)
- Complexity of migration > benefit for small user base

## Open Questions

None - all design decisions finalized based on user's specification.
