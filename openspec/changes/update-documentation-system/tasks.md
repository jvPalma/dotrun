# Update Documentation System - Task List

## Task Organization

Tasks are organized into phases for gradual implementation over 1-2 weeks. Each task is designed to be small, verifiable, and deliver visible progress.

**Parallelizable tasks** are marked with 🔀 (can work on multiple simultaneously)
**Blocking tasks** have explicit dependencies noted

---

## Phase 1: Critical Wiki Updates (Week 1, Days 1-3)

### 1.1 Update Command Name Throughout Wiki

- [ ] 1.1.1 Search wiki for all `drun` references: `grep -r "drun" ~/dotrun.wiki/`
- [ ] 1.1.2 Replace with `dr` in all 40+ markdown files
- [ ] 1.1.3 Update command examples: `drun -l` → `dr -l`, etc.
- [ ] 1.1.4 Verify no `drun` references remain
- [ ] 1.1.5 Test random examples from wiki to ensure accuracy

**Validation:** `grep -r "drun" ~/dotrun.wiki/` returns no results

---

### 1.2 Update Collection Format References

- [ ] 1.2.1 🔀 Search wiki for `.drun-collection.yml`: `grep -r ".drun-collection" ~/dotrun.wiki/`
- [ ] 1.2.2 🔀 Replace with `dotrun.collection.yml` in all files
- [ ] 1.2.3 🔀 Update Collection-Management-Advanced.md metadata section
- [ ] 1.2.4 🔀 Update Collection-Management.md with new format examples
- [ ] 1.2.5 🔀 Verify references match CLAUDE.md specification

**Validation:** `grep -r ".drun-collection" ~/dotrun.wiki/` returns no results

---

### 1.3 Update Collection Metadata Schema

- [ ] 1.3.1 Review current metadata specification in CLAUDE.md
- [ ] 1.3.2 Update Collection-Management-Advanced.md with required fields:
  - name (alphanumeric, dashes, underscores)
  - version (X.Y.Z semantic version)
  - description (under 200 characters)
  - author (creator or organization)
  - repository (Git URL - HTTPS or SSH)
- [ ] 1.3.3 Document optional fields:
  - license (SPDX identifier)
  - homepage (documentation URL)
  - dependencies (array of collection names)
- [ ] 1.3.4 Add complete example with all fields
- [ ] 1.3.5 Document version synchronization with git tags

**Validation:** Metadata example can be copy-pasted and used successfully

---

### 1.4 Update Collection Architecture Documentation

- [ ] 1.4.1 Update Collection-Management-Advanced.md "Architecture" section
- [ ] 1.4.2 Document copy-based approach (vs symlinks)
- [ ] 1.4.3 Explain SHA256 hash tracking for modification detection
- [ ] 1.4.4 Document 8-character hash truncation
- [ ] 1.4.5 Add diagram of copy-based workflow (optional)
- [ ] 1.4.6 Explain `.dr-hashes/` directory structure
- [ ] 1.4.7 Document collections.conf tracking file format

**Validation:** Architecture section accurately reflects code in collections.sh

---

### 1.5 Update Collection Conflict Resolution Documentation

- [ ] 1.5.1 Document three file states during update:
  - Unmodified (hash matches): Update/Diff/Skip options
  - Modified (hash differs): Keep/Overwrite/Diff/Backup options
  - New (in collection, not imported): Import/View/Skip options
- [ ] 1.5.2 Create decision tree for conflict resolution choices
- [ ] 1.5.3 Add examples of each scenario
- [ ] 1.5.4 Document merge workflow for complex conflicts
- [ ] 1.5.5 Add troubleshooting section for common issues

**Validation:** User can follow decision tree without confusion

---

### 1.6 Update Version References

- [ ] 1.6.1 🔀 Search wiki for "v2.0" or "2.0": `grep -r "v2\.0\|2\.0" ~/dotrun.wiki/`
- [ ] 1.6.2 🔀 Review each reference for context (feature reference vs historical)
- [ ] 1.6.3 🔀 Update feature references to v3.0.0
- [ ] 1.6.4 🔀 Keep historical references in CHANGELOG or migration contexts
- [ ] 1.6.5 🔀 Add version indicators where appropriate ("As of v3.0.0...")

**Validation:** All current feature references show v3.0.0 or later

---

## Phase 2: New Feature Documentation (Week 1, Days 4-5)

### 2.1 Create Helper System Documentation

- [ ] 2.1.1 Create new file: `~/dotrun.wiki/Helper-System.md`
- [ ] 2.1.2 Document loadHelpers architecture:
  - Purpose and design philosophy
  - Integration points (DR_LOAD_HELPERS, .drrc)
  - Dual-mode support (dr scriptname vs bash script.sh)
- [ ] 2.1.3 Document 5-level specificity matching:
  - Level 1: Absolute path
  - Level 2: Exact path
  - Level 3: With extension (auto-adds .sh)
  - Level 4: Path search (collection normalization)
  - Level 5: Filename only
- [ ] 2.1.4 Provide pattern examples for each level
- [ ] 2.1.5 Document collection scope loading: `loadHelpers @collection-name`
- [ ] 2.1.6 Document list mode: `loadHelpers pattern --list`
- [ ] 2.1.7 Document environment modes: `DR_HELPERS_VERBOSE=1`, `DR_HELPERS_QUIET=1`

**Validation:** Examples can be copy-pasted and work as documented

---

### 2.2 Document Helper Security Features

- [ ] 2.2.1 Document path traversal prevention:
  - Canonical path validation against $DR_CONFIG/helpers
  - Security check implementation
  - Example of blocked path
- [ ] 2.2.2 Document circular dependency detection:
  - Maximum depth limit (10)
  - Error message and cause
  - How to identify and break cycles
- [ ] 2.2.3 Document de-duplication:
  - Loaded helpers tracking by canonical path
  - Prevention of re-sourcing
  - Performance benefits
- [ ] 2.2.4 Add security best practices section

**Validation:** Security features accurately match loadHelpers.sh implementation

---

### 2.3 Create Collection Author Guidelines for Helpers

- [ ] 2.3.1 Add section to Collection-Authoring.md (or Helper-System.md)
- [ ] 2.3.2 Document loadHelpers function sourcing:
  ```bash
  [[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
  ```
- [ ] 2.3.3 Document flexible pattern usage:
  - `loadHelpers gcp/workstation` - any collection
  - `loadHelpers dotrun-anc/gcp/workstation` - specific collection
  - `loadHelpers @dotrun-anc` - all from collection
- [ ] 2.3.4 Document best practices:
  - Prefer specific patterns over broad patterns
  - Use collection names for uniqueness
  - Test with --list during development
  - Load at top of script before main logic
- [ ] 2.3.5 Provide complete example collection script with helpers
- [ ] 2.3.6 Add troubleshooting section with common errors

**Validation:** Collection author can follow guide to use helpers successfully

---

### 2.4 Update Architecture Overview for Helper System

- [ ] 2.4.1 Open `~/dotrun.wiki/Architecture-Overview.md`
- [ ] 2.4.2 Add "Helper Loading System" section
- [ ] 2.4.3 Document integration architecture:
  - Core location: ~/.local/share/dotrun/helpers/loadHelpers.sh
  - Shell integration: ~/.drrc exports DR_LOAD_HELPERS
  - Script execution: dr binary exports DR_LOAD_HELPERS
- [ ] 2.4.4 Add diagram of helper loading flow
- [ ] 2.4.5 Link to Helper-System.md for detailed documentation

**Validation:** Architecture section provides high-level understanding

---

### 2.5 Document Alias File-Based Workflow

- [ ] 2.5.1 Open `~/dotrun.wiki/Alias-Management.md`
- [ ] 2.5.2 Update workflow section for v3.0:
  - Creating file: `dr aliases set NN-category`
  - File format: one file contains multiple aliases
  - Editing: `dr aliases edit NN-category` (opens $EDITOR)
  - Reloading: `dr aliases reload`
  - Listing: `dr aliases list`
- [ ] 2.5.3 Document numbered prefix convention:
  - Format: `NN-category.aliases` where NN is 01-99
  - Purpose: controls load order
  - Examples: 01-git.aliases, 02-docker.aliases
- [ ] 2.5.4 Explain load order use cases:
  - 01-09: Core/infrastructure (navigation, git)
  - 10-19: Development tools (docker, npm)
  - 20+: Project-specific or custom
- [ ] 2.5.5 Add complete example file with multiple aliases
- [ ] 2.5.6 Document folder organization support

**Validation:** User can create, edit, and reload alias file successfully

---

### 2.6 Document Config File-Based Workflow

- [ ] 2.6.1 Open `~/dotrun.wiki/Configuration-Management.md`
- [ ] 2.6.2 Update workflow section for v3.0:
  - Creating file: `dr config set NN-category`
  - File format: multiple export statements per file
  - Editing: `dr config edit NN-category` (opens $EDITOR)
  - No reload command: must restart shell (`exec $SHELL`)
  - Listing: `dr config list`
- [ ] 2.6.3 Document numbered prefix convention:
  - Format: `NN-category.config` where NN is 01-99
  - Purpose: controls load order (critical for dependencies)
  - Examples: 01-paths.config, 02-api.config
- [ ] 2.6.4 Document load order dependencies:
  - PATH must load before tools that use it
  - Environment variables before apps that read them
  - Example: 01-paths.config before 02-dev.config
- [ ] 2.6.5 Add complete example with PATH de-duplication
- [ ] 2.6.6 Document security considerations (plain text values)
- [ ] 2.6.7 Note planned v3.1.0 feature: `# SECURE` marker

**Validation:** User can create config file and verify variables loaded

---

### 2.7 Document Migration for Aliases/Configs

- [ ] 2.7.1 Open `~/dotrun.wiki/Migration-v3.0.md` (will be moved from root)
- [ ] 2.7.2 Add "Aliases Workflow Changes" section:
  - v2.x: `dr alias set git/gc "git commit"`
  - v3.0: `dr aliases set git` → edit file interactively
  - Rationale: File-based enables multiple aliases per file
- [ ] 2.7.3 Add "Configs Workflow Changes" section:
  - v2.x: `dr config set API_KEY value`
  - v3.0: `dr config set api` → edit file with `export API_KEY=value`
  - Rationale: File-based enables organized configuration
- [ ] 2.7.4 Add migration workflow:
  - Export old aliases/configs
  - Create new files
  - Import old values
  - Remove old format
- [ ] 2.7.5 Add troubleshooting section for migration issues

**Validation:** 2.x user can follow migration guide successfully

---

### 2.8 Document Zsh Completion UX

- [ ] 2.8.1 Open `~/dotrun.wiki/Developer-Experience.md`
- [ ] 2.8.2 Add "Zsh Completion UX" section
- [ ] 2.8.3 Document tier system:
  - Tier 1 (Primary): `dr <tab>` shows folders, scripts, commands, hint
  - Tier 2 (Namespaced): `dr -s <tab>` shows script management
  - Tier 2 (Namespaced): `dr -a <tab>` shows alias management
  - Tier 2 (Namespaced): `dr -c <tab>` shows config management
  - Tier 2 (Namespaced): `dr -col <tab>` shows collection management
- [ ] 2.8.4 Document color scheme:
  - Green: Special commands, script management
  - Yellow: Folders (with trailing /)
  - Cyan: Scripts (without .sh)
  - Purple: Alias management
  - Red: Config management
  - Dark Gray: Hint text
- [ ] 2.8.5 Document hierarchical navigation:
  - `dr folder/<tab>` shows contents
  - `dr folder/subfolder/<tab>` continues
  - Works in management commands: `dr -s add git/<tab>`
- [ ] 2.8.6 Document dual interface:
  - Flag style: `dr -s add`, `dr -a list`
  - Subcommand style: `dr scripts add`, `dr aliases list`
  - Both work identically

**Validation:** Zsh user can understand and use completion effectively

---

## Phase 3: README Simplification (Week 1, Days 6-7)

### 3.1 Audit Current README Content

- [ ] 3.1.1 Read current README.md (465 lines)
- [ ] 3.1.2 List sections and line counts
- [ ] 3.1.3 Mark each section as "keep", "condense", or "move to wiki"
- [ ] 3.1.4 Identify wiki destination for "move" sections
- [ ] 3.1.5 Create checklist of content to preserve

**Validation:** Complete content audit documented

---

### 3.2 Extract Command Organization to Wiki

- [ ] 3.2.1 Copy README lines 90-167 (Command Organization section)
- [ ] 3.2.2 Open `~/dotrun.wiki/API-Reference.md`
- [ ] 3.2.3 Add "Command Organization" section if not exists
- [ ] 3.2.4 Paste content and reformat for wiki
- [ ] 3.2.5 Update examples to match wiki style
- [ ] 3.2.6 Add cross-references to related sections
- [ ] 3.2.7 Verify all information preserved

**Validation:** API-Reference.md contains complete command organization

---

### 3.3 Extract Collections System to Wiki

- [ ] 3.3.1 Copy README lines 168-346 (Collections System section, 178 lines)
- [ ] 3.3.2 Open `~/dotrun.wiki/Collection-Management-Advanced.md`
- [ ] 3.3.3 Identify where to integrate content (avoid duplication)
- [ ] 3.3.4 Merge or append content
- [ ] 3.3.5 Update for v3.0.0 accuracy (already done in Phase 1)
- [ ] 3.3.6 Remove any duplicate information
- [ ] 3.3.7 Add cross-references

**Validation:** Collection-Management-Advanced.md is comprehensive reference

---

### 3.4 Extract Other Detailed Sections

- [ ] 3.4.1 🔀 Extract "Update Workflow" (lines 237-263) → Collection-Management-Advanced.md
- [ ] 3.4.2 🔀 Extract "Private Repo Support" (lines 265-278) → Collection-Management-Advanced.md
- [ ] 3.4.3 🔀 Extract "Team Workflow Example" (lines 280-306) → Team-Workflows.md
- [ ] 3.4.4 🔀 Extract "Collection Metadata Format" (lines 308-323) → Collection-Authoring.md
- [ ] 3.4.5 🔀 Extract "Real-World Example" (lines 399-411) → User-Guide.md or Script-Examples.md
- [ ] 3.4.6 🔀 Extract "Popular Use Cases" (lines 420-427) → Create new Use-Cases.md

**Validation:** Each section successfully moved to appropriate wiki page

---

### 3.5 Create Simplified README

- [ ] 3.5.1 Create backup: `cp README.md README.md.backup`
- [ ] 3.5.2 Open README.md for editing
- [ ] 3.5.3 Keep sections (condense where needed):
  - Title, badges, tagline (lines 1-10)
  - The Problem (lines 11-21) - keep
  - The Solution (lines 22-34) - keep
  - 30-Second Demo (lines 36-49) - keep
  - Before vs After (lines 51-70) - keep
  - Why DotRun? (lines 72-78) - condense to 3-4 lines
  - Key Features (lines 79-89) - bullet points only, 5 items max
- [ ] 3.5.4 Delete detailed sections:
  - Command Organization (lines 90-167)
  - Collections System detail (lines 168-346)
  - Keep 5-line collections overview
- [ ] 3.5.5 Keep Installation (lines 348-354) - maybe condense
- [ ] 3.5.6 Keep Quick Start (lines 356-397) - maybe condense
- [ ] 3.5.7 Update "Documentation" section with wiki links
- [ ] 3.5.8 Keep Requirements (lines 447-451)
- [ ] 3.5.9 Keep footer links

**Validation:** README is ~200 lines and reads smoothly in < 5 minutes

---

### 3.6 Add Wiki Links to README

- [ ] 3.6.1 Create "Documentation" section in README
- [ ] 3.6.2 Add links to primary wiki pages:
  - Installation Guide
  - User Guide
  - Script Development
  - Collection Management
  - Helper System
  - FAQ
  - Migration Guide (for 2.x users)
- [ ] 3.6.3 Add brief description per link
- [ ] 3.6.4 Group links by category (Getting Started, User Guides, Reference)
- [ ] 3.6.5 Test all links resolve correctly

**Validation:** All wiki links work, README has clear navigation

---

### 3.7 Update README Cross-References

- [ ] 3.7.1 Update "Learn More" references to point to wiki
- [ ] 3.7.2 Add "See also" inline references where content moved
- [ ] 3.7.3 Example: "For detailed command reference, see [API Reference](wiki link)"
- [ ] 3.7.4 Ensure smooth reading flow with wiki pointers
- [ ] 3.7.5 Remove broken or outdated links

**Validation:** README reads naturally with wiki pointers

---

## Phase 4: Migration Guide and FAQ (Week 2, Days 1-2)

### 4.1 Move Migration Guide to Wiki

- [ ] 4.1.1 Verify `MIGRATION-v3.0.md` exists in repository root (597 lines)
- [ ] 4.1.2 Copy to `~/dotrun.wiki/Migration-v3.0.md`
- [ ] 4.1.3 Verify content unchanged (all 597 lines preserved)
- [ ] 4.1.4 Add to git: `cd ~/dotrun.wiki && git add Migration-v3.0.md`
- [ ] 4.1.5 Commit: `git commit -m "Add v3.0 migration guide to wiki"`
- [ ] 4.1.6 Update wiki navigation/sidebar to include Migration-v3.0
- [ ] 4.1.7 Remove from repository root: `cd ~/dotrun && git rm MIGRATION-v3.0.md`
- [ ] 4.1.8 Commit removal: `git commit -m "Move migration guide to wiki"`

**Validation:** Migration guide accessible via wiki, removed from root

---

### 4.2 Link Migration Guide from Home Page

- [ ] 4.2.1 Open `~/dotrun.wiki/Home.md`
- [ ] 4.2.2 Add "Upgrading from v2.x?" section near top
- [ ] 4.2.3 Link to Migration-v3.0.md with clear call-to-action
- [ ] 4.2.4 Add to "Getting Started" section as well
- [ ] 4.2.5 Verify link works

**Validation:** Migration guide easily discoverable from wiki home

---

### 4.3 Create Comprehensive FAQ

- [ ] 4.3.1 Open `~/dotrun.wiki/FAQ.md` (324 lines currently)
- [ ] 4.3.2 Review existing content
- [ ] 4.3.3 Add "Installation & Setup" category:
  - Installation failed with permission error
  - How do I upgrade from v2.x to v3.x?
  - Shell integration not working after install
  - Tab completion not appearing
  - EDITOR not set error
- [ ] 4.3.4 Add "Scripts" category:
  - How do I create my first script?
  - Can I organize scripts in folders?
  - How do I document scripts with DOC tokens?
  - Script not found but I just created it
  - Helper loading fails
- [ ] 4.3.5 Add "Aliases & Configs" category:
  - What's the difference between scripts and aliases?
  - How do aliases differ in v3.0 vs v2.x?
  - What is the NN-category naming convention?
  - How do I control load order?
  - Why aren't my configs loading?

**Validation:** FAQ covers 20+ common questions

---

### 4.4 Add Collections FAQ Section

- [ ] 4.4.1 Add "Collections" category to FAQ:
  - What are collections and do I need them?
  - How do I install a private collection?
  - What happens when I update a collection?
  - Can I modify imported collection scripts?
  - Collection sync failing with git errors
  - What is SHA256 hash tracking?
  - Old collection format vs new format
  - How do I resolve update conflicts?
- [ ] 4.4.2 Each answer should be 2-3 lines + link to detailed guide
- [ ] 4.4.3 Link to Collection-Management.md sections
- [ ] 4.4.4 Include example commands where applicable

**Validation:** Collections questions well-covered with links

---

### 4.5 Add Advanced Topics FAQ Section

- [ ] 4.5.1 Add "Advanced" category to FAQ:
  - How do I use helpers in my scripts?
  - What is loadHelpers and how does it work?
  - Can I integrate DotRun with CI/CD?
  - How do I share scripts with my team?
  - Performance issues with large script libraries
  - How do I create a collection?
- [ ] 4.5.2 Link to Helper-System.md, Collection-Authoring.md, etc.
- [ ] 4.5.3 Provide quick answers with "Learn more" links

**Validation:** Advanced topics accessible via FAQ

---

### 4.6 Link FAQ from Other Pages

- [ ] 4.6.1 Update Home.md to link to FAQ prominently
- [ ] 4.6.2 Add "Common Questions" callouts in detailed guides:
  - Script-Management.md → "See FAQ: Script issues"
  - Collection-Management.md → "See FAQ: Collection questions"
  - Helper-System.md → "See FAQ: Helper loading"
- [ ] 4.6.3 Add FAQ references in troubleshooting sections
- [ ] 4.6.4 Ensure bidirectional linking (FAQ → guides, guides → FAQ)

**Validation:** FAQ integrated into documentation navigation

---

## Phase 5: Cross-References and Navigation (Week 2, Days 3-4)

### 5.1 Add Breadcrumbs to All Wiki Pages

- [ ] 5.1.1 Identify all wiki pages (40+ files)
- [ ] 5.1.2 For each page, add breadcrumb trail at top:
  - Format: `Home > Section > Page`
  - Example: `Home > User Guides > Script Management`
- [ ] 5.1.3 Make breadcrumbs clickable links
- [ ] 5.1.4 Use consistent formatting across all pages
- [ ] 5.1.5 Test breadcrumb links

**Validation:** All wiki pages have working breadcrumbs

---

### 5.2 Add "See Also" Sections

- [ ] 5.2.1 For each major wiki page, add "See Also" section at bottom
- [ ] 5.2.2 Link to 2-5 related pages
- [ ] 5.2.3 Include brief description per link
- [ ] 5.2.4 Prioritize most relevant related topics
- [ ] 5.2.5 Examples:
  - Script-Management.md → Collection-Management, Helper-System, Script-Examples
  - Collection-Management.md → Collection-Authoring, Migration-v3.0, FAQ
  - Helper-System.md → Script-Development, Collection-Authoring, Architecture

**Validation:** Each page has useful related links

---

### 5.3 Create Topic Index

- [ ] 5.3.1 Create new file: `~/dotrun.wiki/Topic-Index.md` (or add to Home.md)
- [ ] 5.3.2 List all major topics alphabetically
- [ ] 5.3.3 Add brief description per topic
- [ ] 5.3.4 Link to relevant page and section
- [ ] 5.3.5 Include synonyms (e.g., "Aliases" and "Shell Shortcuts")
- [ ] 5.3.6 Keep index updated with new pages

**Validation:** User can find any topic via alphabetical index

---

### 5.4 Update Internal Links

- [ ] 5.4.1 Audit all wiki pages for internal links
- [ ] 5.4.2 Update broken links (pages moved or renamed)
- [ ] 5.4.3 Convert absolute URLs to relative where appropriate
- [ ] 5.4.4 Use consistent anchor format (lowercase, hyphens)
- [ ] 5.4.5 Test all internal links resolve

**Validation:** No broken internal links in wiki

---

### 5.5 Add Search Keywords

- [ ] 5.5.1 For each major wiki page, add:
  - Clear title (under 50 characters)
  - Description paragraph (first paragraph)
  - Keywords at bottom or in frontmatter (if supported)
  - Alternative terms and synonyms
- [ ] 5.5.2 Examples:
  - Script-Management.md: keywords [scripts, commands, automation, executables]
  - Helper-System.md: keywords [helpers, modules, libraries, shared code, loadHelpers]
- [ ] 5.5.3 Optimize for GitHub wiki search

**Validation:** Pages discoverable via relevant keyword searches

---

## Phase 6: Validation and Polish (Week 2, Days 4-5)

### 6.1 Validate Content Completeness

- [ ] 6.1.1 Review original README sections against wiki
- [ ] 6.1.2 Verify all README content accounted for (moved or intentionally removed)
- [ ] 6.1.3 Review MIGRATION-v3.0.md content preserved in wiki
- [ ] 6.1.4 Check all code examples exist somewhere in docs
- [ ] 6.1.5 Verify no information lost during reorganization

**Validation:** Content audit shows 100% preservation

---

### 6.2 Validate v3.0.0 Accuracy

- [ ] 6.2.1 Search wiki for command name: should be `dr` everywhere
- [ ] 6.2.2 Search for collection format: should be `dotrun.collection.yml`
- [ ] 6.2.3 Search for version references: should be v3.0.0 for current features
- [ ] 6.2.4 Review collection architecture matches collections.sh
- [ ] 6.2.5 Review helper system matches loadHelpers.sh

**Validation:** All v3.0.0 features accurately documented

---

### 6.3 Test Code Examples

- [ ] 6.3.1 Identify all code examples in wiki (scripts, commands, config snippets)
- [ ] 6.3.2 Test random sample (20-30 examples) for correctness
- [ ] 6.3.3 Verify command flags match `dr --help` output
- [ ] 6.3.4 Verify collection metadata examples are valid
- [ ] 6.3.5 Fix any incorrect or outdated examples
- [ ] 6.3.6 Add expected output where helpful

**Validation:** Tested examples work as documented

---

### 6.4 Link Validation

- [ ] 6.4.1 🔀 Check all README links to wiki: `grep -o 'http[s]\?://[^)]*' README.md`
- [ ] 6.4.2 🔀 Check all wiki internal links
- [ ] 6.4.3 🔀 Check all wiki links to external resources
- [ ] 6.4.4 🔀 Test random sample of links manually
- [ ] 6.4.5 🔀 Fix broken links
- [ ] 6.4.6 🔀 Consider using link checker tool if available

**Validation:** No broken links in README or wiki

---

### 6.5 Consistency Check

- [ ] 6.5.1 Verify consistent terminology across all pages
  - "script" vs "command" vs "executable"
  - "collection" vs "repository"
  - "helper" vs "module"
- [ ] 6.5.2 Verify consistent command format:
  - Code blocks use `bash` syntax highlighting
  - Commands use same flag style
  - Examples use consistent variable names
- [ ] 6.5.3 Verify consistent formatting:
  - Section headers use same hierarchy
  - Lists use same style (bullet vs numbered)
  - Code blocks use same style
- [ ] 6.5.4 Fix inconsistencies

**Validation:** Documentation has consistent voice and style

---

### 6.6 Readability Review

- [ ] 6.6.1 Read through README from first-time user perspective
  - Understandable in < 5 minutes?
  - Value proposition clear?
  - Quick start achievable?
- [ ] 6.6.2 Review Installation Guide for clarity
- [ ] 6.6.3 Review Quick Start Tutorial for completeness
- [ ] 6.6.4 Review Migration Guide for 2.x user
- [ ] 6.6.5 Review FAQ for common questions
- [ ] 6.6.6 Get feedback from team member or friend (optional)

**Validation:** Documentation clear and approachable

---

### 6.7 OpenSpec Validation

- [ ] 6.7.1 Run: `openspec validate update-documentation-system --strict`
- [ ] 6.7.2 Fix any validation errors
- [ ] 6.7.3 Verify all requirements have scenarios
- [ ] 6.7.4 Verify tasks map to requirements
- [ ] 6.7.5 Re-run validation after fixes

**Validation:** `openspec validate --strict` passes with no errors

---

### 6.8 Final Polish

- [ ] 6.8.1 🔀 Fix typos and grammar errors
- [ ] 6.8.2 🔀 Improve unclear explanations
- [ ] 6.8.3 🔀 Add clarifying examples where needed
- [ ] 6.8.4 🔀 Improve visual formatting (bold, italics, code blocks)
- [ ] 6.8.5 🔀 Check markdown renders correctly on GitHub
- [ ] 6.8.6 🔀 Add emojis sparingly for visual interest (optional)

**Validation:** Documentation polished and professional

---

## Phase 7: Deployment and Wrap-Up (Week 2, Day 5)

### 7.1 Commit Wiki Changes

- [ ] 7.1.1 Review all wiki changes: `cd ~/dotrun.wiki && git status`
- [ ] 7.1.2 Stage changes: `git add .`
- [ ] 7.1.3 Commit with message: `git commit -m "Update documentation for v3.0.0"`
- [ ] 7.1.4 Push to wiki: `git push origin master`
- [ ] 7.1.5 Verify changes appear on GitHub wiki

**Validation:** Wiki updated on GitHub

---

### 7.2 Commit README Changes

- [ ] 7.2.1 Review README changes: `cd ~/dotrun && git status README.md`
- [ ] 7.2.2 Stage: `git add README.md`
- [ ] 7.2.3 Commit: `git commit -m "Simplify README, move detailed docs to wiki"`
- [ ] 7.2.4 Push: `git push origin main`
- [ ] 7.2.5 Verify README renders correctly on GitHub

**Validation:** Simplified README live on GitHub

---

### 7.3 Verify MIGRATION-v3.0.md Moved

- [ ] 7.3.1 Confirm MIGRATION-v3.0.md no longer in repository root
- [ ] 7.3.2 Confirm available in wiki at Migration-v3.0.md
- [ ] 7.3.3 Verify README links to wiki version
- [ ] 7.3.4 Test link from README to migration guide

**Validation:** Migration guide accessible only via wiki

---

### 7.4 Update CHANGELOG

- [ ] 7.4.1 Open CHANGELOG.md
- [ ] 7.4.2 Add entry under "Unreleased" or next version:

  ```markdown
  ### Documentation

  - Simplified README to focus on quick start and value proposition
  - Updated wiki documentation for v3.0.0 accuracy
  - Documented loadHelpers system architecture
  - Documented file-based alias and config workflows
  - Documented Zsh completion UX
  - Added comprehensive FAQ with 30+ questions
  - Moved MIGRATION-v3.0.md to wiki for discoverability
  ```

- [ ] 7.4.3 Commit CHANGELOG update

**Validation:** CHANGELOG documents documentation improvements

---

### 7.5 Archive OpenSpec Change

- [ ] 7.5.1 Run: `openspec archive update-documentation-system`
- [ ] 7.5.2 Verify change marked as archived
- [ ] 7.5.3 Verify all tasks marked complete
- [ ] 7.5.4 Add archive note with completion date

**Validation:** OpenSpec change archived successfully

---

### 7.6 Create Follow-Up Issues (Optional)

- [ ] 7.6.1 Identify any incomplete or future work
- [ ] 7.6.2 Create GitHub issues for:
  - Additional examples needed
  - Advanced topics to expand
  - Future FAQ questions
  - Diagrams to add
- [ ] 7.6.3 Label issues appropriately (documentation, enhancement)

**Validation:** Future work documented as issues

---

## Summary Statistics

**Total Tasks:** 140 tasks across 7 phases

**Estimated Hours:**

- Phase 1 (Critical Wiki Updates): 8-12 hours
- Phase 2 (New Feature Documentation): 10-14 hours
- Phase 3 (README Simplification): 4-6 hours
- Phase 4 (Migration & FAQ): 6-8 hours
- Phase 5 (Cross-References): 4-6 hours
- Phase 6 (Validation & Polish): 6-8 hours
- Phase 7 (Deployment): 2-3 hours

**Total: 40-57 hours over 1-2 weeks**

**Parallelizable Tasks:** ~30 tasks (marked with 🔀)
**Blocking Dependencies:** Phases are sequential but tasks within phases can often be parallelized

**Progress Tracking:**

- Use this task list to track completion
- Mark tasks with ✅ as completed
- Update OpenSpec periodically: `openspec update update-documentation-system`
- Review progress weekly

**Success Criteria:**

- All 140 tasks completed ✅
- OpenSpec validation passes
- README ≤ 250 lines
- Wiki comprehensive and accurate
- No broken links
- User feedback positive
