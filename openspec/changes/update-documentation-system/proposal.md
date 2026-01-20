# Update Documentation System

## Summary

Update and reorganize DotRun's documentation by:

1. **Updating existing wiki** (40 pages, ~14,261 lines) to v3.0.0 standards
2. **Simplifying README.md** from 465 lines to ~200 lines (entry point only)
3. **Migrating MIGRATION-v3.0.md** to wiki for permanent discoverability
4. **Reorganizing content** by resource type (scripts, aliases, configs, collections)
5. **Creating comprehensive FAQ** from GitHub issues and common questions

## Why

### Current State Problems

**Wiki Exists But Outdated:**

- 40 markdown files (~14,261 lines) with comprehensive coverage
- References **v2.0.0 features** but repo is now at **v3.0.0**
- Documents **old collection format** (`.drun-collection.yml`) vs new (`dotrun.collection.yml`)
- Missing critical v3.0.0 features: loadHelpers system, NN-category naming, Zsh completion UX
- Command name inconsistency (`drun` in wiki vs `dr` in actual code)
- Broken internal links and outdated examples

**README.md Issues:**

- **465 lines** - overwhelming for first-time visitors
- Contains complete feature documentation that should be in wiki
- Collections section (lines 168-346) is 178 lines of comprehensive docs
- Command organization (lines 90-167) is 77 lines of detailed reference
- Links to wiki pages that need updating
- Duplicates content that exists in wiki

**MIGRATION-v3.0.md Problems:**

- **597 lines** of valuable v2.x → v3.0.0 migration content
- Currently in repository root (untracked file)
- Not discoverable via wiki navigation
- Will be lost or forgotten over time
- Should be permanent wiki resource for upgraders

**Documentation Gaps:**

- **loadHelpers system** - 5-level specificity matching completely undocumented
- **Collection architecture** - Copy-based with SHA256 tracking not explained
- **Alias/Config naming** - NN-category.{aliases|config} convention undocumented
- **Zsh completion UX** - Namespace-based system with colors undocumented
- **Helper security** - Path traversal prevention, circular dependency detection
- **FAQ** - No centralized troubleshooting resource

### User Impact

**First-Time Users:**

- Face wall of text in README instead of clear value proposition
- Must read 465 lines to understand basics
- 30-second demo buried in lengthy content
- Wiki exists but is outdated/incomplete

**Existing Users (2.x → 3.0):**

- Cannot find migration guide via wiki
- Encounter breaking changes without clear upgrade path
- Old wiki references confuse about actual behavior
- Collection system documentation doesn't match implementation

**Power Users:**

- Cannot find documentation for advanced features (loadHelpers)
- No reference for collection authoring (metadata format changed)
- Missing best practices for team workflows
- Troubleshooting requires reading source code

**Contributors:**

- Architecture documentation scattered (CLAUDE.md vs wiki)
- No clear place to add new feature documentation
- Risk of README bloat with each new feature

## What Changes

### 1. Update Existing Wiki (Priority: Critical)

**Update for v3.0.0 Consistency:**

- Update command name: `drun` → `dr` throughout
- Fix collection format references: `.drun-collection.yml` → `dotrun.collection.yml`
- Update collection architecture documentation: copy-based with SHA256 tracking
- Update metadata schema with required fields (name, version, author, repository, description)
- Fix broken internal links
- Update code examples to match current implementation

**Add Missing v3.0.0 Features:**

- **loadHelpers System** (new Architecture section):
  - 5-level specificity matching (absolute → exact → extension → path → filename)
  - Collection loading patterns (`@collection-name`)
  - Security features (path traversal, circular dependency, de-duplication)
  - Collection author guidelines
  - Troubleshooting guide

- **Alias/Config Management** (update existing pages):
  - Numbered prefix convention: `NN-category.{aliases|config}`
  - Load order control with examples
  - Category organization patterns
  - Migration from 2.x workflow

- **Zsh Completion UX** (new section in Developer-Experience.md):
  - Namespace-based organization (`-s`, `-a`, `-c`, `-col`)
  - Color scheme and tier system
  - Hierarchical folder navigation
  - Dual interface (flag vs subcommand)

**Migrate Content from Repository:**

- Move `MIGRATION-v3.0.md` (597 lines) → `wiki/Migration-v3.0.md`
- Extract detailed collections content from README → enhance `wiki/Collection-Management-Advanced.md`
- Extract command organization from README → enhance `wiki/API-Reference.md`

### 2. Simplify README.md

**Target: Reduce from 465 lines to ~200 lines**

**Keep (Essential Entry Point):**

- Problem statement ("Stop hunting for commands")
- 30-second demo (install → create → run)
- Before/After comparison
- Why DotRun? (vs alternatives)
- Key Features (condensed to 5 bullet points)
- Quick Start (5 minutes to first script)
- Core Workflow (5-step process)
- Requirements (OS, Shell, Dependencies)
- Documentation links section

**Move to Wiki:**

- Command Organization (lines 90-167, 77 lines) → `API-Reference.md`
- Collections System (lines 168-346, 178 lines) → `Collection-Management-Advanced.md`
- Update Workflow details (lines 237-263) → `Collection-Management-Advanced.md`
- Private Repo Support (lines 265-278) → `Collection-Management-Advanced.md`
- Team Workflow Example (lines 280-306) → `Team-Workflows.md`
- Collection Metadata Format (lines 308-323) → `Collection-Management-Advanced.md`
- Real-World Example (lines 399-411) → `User-Guide.md`
- Popular Use Cases (lines 420-427) → Create new `Use-Cases.md`

**New README Structure (~200 lines):**

```markdown
# DotRun

[Badges]

**Stop hunting for commands. Start running them.**

## The Problem [~20 lines]

## The Solution [~20 lines]

## 30-Second Demo [~30 lines]

## Why DotRun? [~20 lines - condensed]

## Key Features [~10 lines - bullet points only]

## Installation [~20 lines - one-liner + basic]

## Quick Start [~30 lines]

## Core Workflow [~10 lines]

## Documentation [~20 lines - wiki links]

## Requirements [~10 lines]

## Get Started [~10 lines - quick links]
```

### 3. Reorganize Wiki by Resource Type

**Create Clear Section Structure:**

**Getting Started/**

- `Home.md` - Update navigation for v3.0.0
- `Installation-Guide.md` - Update, add v3.0.0 specifics
- `Quick-Start-Tutorial.md` - Update examples
- `Migration-v3.0.md` - **NEW** (from root MIGRATION-v3.0.md)

**User Guides/** (by resource type)

- `Script-Management.md` - Consolidate Script-Development\*.md files
  - Creation, organization, documentation
  - DOC token system
  - Folder hierarchy
  - Best practices

- `Alias-Management.md` - **Update for v3.0.0**
  - File-based workflow (breaking change from 2.x)
  - NN-category.aliases naming convention
  - Load order control
  - Examples and migration guide

- `Configuration-Management.md` - **Update for v3.0.0**
  - File-based workflow (breaking change from 2.x)
  - NN-category.config naming convention
  - Load order dependencies (PATH before tools)
  - Security considerations

- `Collection-Management.md` - **Major update**
  - User perspective: install, update, sync
  - Update workflow with conflict resolution
  - SHA256 modification detection
  - Private repository support (SSH/HTTPS)

- `Collection-Authoring.md` - **NEW** (split from Collection-Management)
  - Creating collections (`dr -col init`)
  - Metadata format: `dotrun.collection.yml` specification
  - Directory structure requirements
  - Version tagging and semantic versioning
  - Testing and validation
  - Distribution (public/private)

**Advanced Topics/**

- `Helper-System.md` - **NEW**
  - loadHelpers architecture
  - 5-level specificity matching
  - Security features
  - Collection integration
  - Troubleshooting

- `Developer-Experience.md` - **Update**
  - Add Zsh completion UX section
  - Namespace-based organization
  - Color scheme
  - Hierarchical navigation

**Reference/**

- `API-Reference.md` - **Update**
  - Add command organization from README
  - Namespace system (`-s`, `-a`, `-c`, `-col`)
  - Complete flag reference

- `Architecture-Overview.md` - **Update**
  - Add loadHelpers system architecture
  - Update collection architecture (copy-based)

- `FAQ.md` - **Expand**
  - Migration questions (2.x → 3.0)
  - Troubleshooting by category
  - Common gotchas

**Workflows/** (existing)

- Keep existing 8 team workflow files
- Update for v3.0.0 consistency
- Extract common patterns to shared libraries

### 4. Create Comprehensive FAQ

**Categories:**

**Installation & Setup:**

- Installation failed with permission error
- How do I upgrade from v2.x to v3.x?
- Shell integration not working after install
- Tab completion not appearing
- EDITOR not set error

**Scripts:**

- How do I create my first script?
- Can I organize scripts in folders?
- How do I document scripts with DOC tokens?
- Script not found but I just created it
- Helper loading fails

**Aliases & Configs:**

- What's the difference between scripts and aliases?
- How do aliases differ in v3.0 vs v2.x? (file-based workflow)
- What is the NN-category naming convention?
- How do I control load order?
- Why aren't my configs loading?

**Collections:**

- What are collections and do I need them?
- How do I install a private collection?
- What happens when I update a collection?
- Can I modify imported collection scripts?
- Collection sync failing with git errors
- What is SHA256 hash tracking?
- Old collection format vs new format

**Advanced:**

- How do I use helpers in my scripts?
- What is loadHelpers and how does it work?
- Can I integrate DotRun with CI/CD?
- How do I share scripts with my team?
- Performance issues with large script libraries

**Link to Detailed Guides:**
Each FAQ answer should:

- Provide quick answer (2-3 lines)
- Link to relevant wiki section for details
- Include example command if applicable

### 5. Cross-Referencing System

**Bidirectional Linking:**

- README → Wiki (all primary pages)
- Wiki pages → Related pages (See Also sections)
- FAQ → Detailed guides (inline links)
- Detailed guides → FAQ (common questions callouts)

**Navigation Improvements:**

- Add breadcrumbs to all wiki pages
- Create topic index (alphabetical)
- Add "Related Topics" sections
- Use consistent anchor link format

### 6. Content Validation

**Ensure No Content Loss:**

- All README content preserved in wiki or removed intentionally
- All MIGRATION-v3.0.md content preserved
- All examples retained and updated
- All code samples verified against current implementation

**Ensure Consistency:**

- Command name: `dr` everywhere (not `drun`)
- Collection format: `dotrun.collection.yml` everywhere
- Version references: v3.0.0 throughout
- Code examples match actual behavior
- Links all resolve correctly

## Impact

### Affected Files

**Modified:**

- `README.md` - Reduced from 465 to ~200 lines
- `~/dotrun.wiki/*.md` - 40+ files updated for v3.0.0

**Moved:**

- `MIGRATION-v3.0.md` → `~/dotrun.wiki/Migration-v3.0.md`

**New Wiki Pages:**

- `~/dotrun.wiki/Helper-System.md` - loadHelpers documentation
- `~/dotrun.wiki/Collection-Authoring.md` - Split from Collection-Management
- `~/dotrun.wiki/Use-Cases.md` - Expanded from README section

**Unchanged:**

- `CHANGELOG.md` - Remains in root
- `CLAUDE.md` - Remains in root (internal docs)
- `AGENTS.md` - Remains in root (OpenSpec)
- `LICENSE` - Remains in root

### Affected Specs

**New Capability:** `documentation-system`

This is a new capability covering the entire documentation infrastructure. It is separate from existing specs (like `collections`) because documentation is a cross-cutting concern serving all features.

### Benefits

**For First-Time Users:**

- ✨ Clear value proposition in ~30 seconds
- ✨ Quick start achievable in 5 minutes
- ✨ Not overwhelmed by detailed documentation
- ✨ Clear path to comprehensive guides

**For Existing Users (Upgraders):**

- ✨ Migration guide discoverable via wiki
- ✨ Clear upgrade path from 2.x to 3.0
- ✨ Breaking changes well-documented
- ✨ FAQ addresses common questions

**For Power Users:**

- ✨ Advanced features fully documented
- ✨ Helper system architecture explained
- ✨ Collection authoring guide complete
- ✨ Best practices consolidated

**For Contributors:**

- ✨ Architecture documentation up-to-date
- ✨ Clear place to add new feature docs
- ✨ Consistent documentation patterns
- ✨ Easy to maintain separate concerns

**For Maintenance:**

- ✨ README stays focused and short
- ✨ Individual pages easier to update
- ✨ Version-specific migration guides preserved
- ✨ Reduced duplication across docs

### Risks

**Content Drift:**

- Wiki may become outdated again
- Mitigation: Add wiki update to release checklist

**Broken Links:**

- Internal links may break during reorganization
- Mitigation: Comprehensive link validation step

**User Confusion:**

- Users may have bookmarked old wiki pages
- Mitigation: Add redirects where possible, update Home.md navigation

**Incomplete Migration:**

- Risk of losing content during migration
- Mitigation: Systematic content audit, validation checklist

## Validation

**Completeness:**

- [ ] All README content accounted for (moved or removed intentionally)
- [ ] All MIGRATION-v3.0.md content preserved
- [ ] All v3.0.0 features documented
- [ ] No broken links in README or wiki
- [ ] All code examples verified against implementation

**Consistency:**

- [ ] Command name `dr` used throughout (not `drun`)
- [ ] Collection format `dotrun.collection.yml` everywhere
- [ ] Version references updated to v3.0.0
- [ ] Metadata schema matches implementation
- [ ] Examples match current behavior

**Usability:**

- [ ] README understandable in < 5 minutes
- [ ] Quick start achievable by new user
- [ ] Migration guide clear for 2.x users
- [ ] FAQ answers common questions
- [ ] Navigation paths clear and intuitive

**Technical:**

- [ ] `openspec validate update-documentation-system --strict` passes
- [ ] All wiki pages render correctly in GitHub
- [ ] Cross-references resolve correctly
- [ ] No duplicate content across pages

## Dependencies

**Blocked By:** None (documentation-only change)

**Blocks:** None (can proceed independently)

**Related Changes:**

- `unify-resource-workflows` - Currently active, 15/33 tasks complete
- May want to document unified workflow in wiki after completion

## Timeline

**Estimated Effort:**

- **Planning & Spec**: 3-4 hours (this document)
- **Wiki Updates**: 12-16 hours (40+ pages to review/update)
- **README Simplification**: 2-3 hours
- **Migration Guide Move**: 1-2 hours
- **New Content (Helper System, etc.)**: 6-8 hours
- **FAQ Creation**: 3-4 hours
- **Cross-References & Links**: 2-3 hours
- **Validation & Testing**: 3-4 hours

**Total: 32-44 hours over 1-2 weeks**

**Phased Approach:**

- **Phase 1 (Week 1)**: Critical updates (collections format, loadHelpers, v3.0.0 consistency)
- **Phase 2 (Week 1-2)**: README simplification, migration guide move
- **Phase 3 (Week 2)**: New content (FAQ, use cases), cross-references
- **Phase 4 (Week 2)**: Validation, link checking, polish

## Alternatives Considered

### Alternative 1: Keep README Comprehensive

**Approach:** Keep all documentation in README, just reorganize

**Rejected Because:**

- README would still be 400+ lines (too long)
- Doesn't solve navigation problem
- Single file harder to maintain
- Wiki already exists with good structure

### Alternative 2: Start Wiki from Scratch

**Approach:** Delete existing wiki, create new structure

**Rejected Because:**

- Would lose 14,261 lines of good content
- Existing structure is sound, just needs updates
- Many pages (workflows, examples) are still valuable
- Would take much longer to rewrite everything

### Alternative 3: Documentation Website

**Approach:** Use Docusaurus/GitBook/MkDocs for documentation

**Rejected Because:**

- Overhead of external hosting and deployment
- GitHub wiki is standard and sufficient
- Adds complexity for minimal benefit
- Contributors already familiar with wiki

### Alternative 4: Split into Multiple Changes

**Approach:** Create separate changes for each wiki section

**Rejected Because:**

- Pages are interdependent (cross-references)
- Would create inconsistent state during partial deployment
- More OpenSpec overhead for little benefit
- Single comprehensive change is more atomic

## Success Criteria

**README:**

- [ ] Reduced to ≤ 250 lines (from 465)
- [ ] Value proposition clear within 60 seconds of reading
- [ ] Quick start achievable in 5 minutes
- [ ] All wiki links functional

**Wiki:**

- [ ] All 40+ pages reviewed and updated for v3.0.0
- [ ] No references to old formats or commands
- [ ] Migration guide accessible from Home.md
- [ ] FAQ has ≥ 30 questions with answers
- [ ] Helper system fully documented
- [ ] Collection authoring guide complete

**Content Quality:**

- [ ] All code examples tested and working
- [ ] No broken internal links
- [ ] Consistent terminology throughout
- [ ] No duplicate content across pages
- [ ] Search keywords added to all pages

**User Experience:**

- [ ] First-time user can install and create script in < 10 minutes
- [ ] 2.x user can find and follow migration guide
- [ ] Power user can find advanced topics (helpers, authoring)
- [ ] Contributor can understand architecture

## Next Steps

1. **Review & Approval** - Get stakeholder sign-off on this proposal
2. **Create Spec Deltas** - Write detailed requirements for documentation-system capability
3. **Create Task List** - Break down into 40-50 granular tasks
4. **Validate OpenSpec** - Run `openspec validate --strict`
5. **Begin Implementation** - Start with Phase 1 (critical updates)
6. **Iterate** - Update proposal if new requirements discovered
7. **Archive** - After all tasks complete and wiki is validated
