# Documentation System Specification

## ADDED Requirements

### Requirement: Wiki Structure and Organization

The wiki SHALL maintain a hierarchical structure organized by user journey and resource type.

#### Scenario: Getting Started section exists

- **WHEN** new user visits wiki
- **THEN** Home.md SHALL provide clear navigation paths by user role
- **AND** Installation-Guide.md SHALL document setup for all platforms (Linux, macOS, WSL)
- **AND** Quick-Start-Tutorial.md SHALL enable first script creation within 5 minutes
- **AND** Migration-v3.0.md SHALL document upgrade path from 2.x to 3.0

#### Scenario: User Guides organized by resource type

- **WHEN** user explores features
- **THEN** wiki SHALL contain dedicated guides for each resource:
  - Script-Management.md (creation, organization, documentation)
  - Alias-Management.md (file-based workflow, NN-category naming)
  - Configuration-Management.md (file-based workflow, load order)
  - Collection-Management.md (user perspective: install, update, sync)
  - Collection-Authoring.md (author perspective: create, version, distribute)
- **AND** each guide SHALL focus on single resource type
- **AND** guides SHALL include examples and troubleshooting

#### Scenario: Advanced Topics section

- **WHEN** power user seeks advanced features
- **THEN** wiki SHALL document:
  - Helper-System.md (loadHelpers architecture and usage)
  - Developer-Experience.md (shell completions, editor integration)
  - Team-Workflows.md (collaboration patterns)
  - Performance-Optimization.md (scaling to 100+ scripts)
- **AND** each page SHALL link to related basic guides

#### Scenario: Reference section

- **WHEN** user needs detailed reference
- **THEN** wiki SHALL provide:
  - API-Reference.md (complete command reference)
  - Architecture-Overview.md (system design)
  - FAQ.md (troubleshooting and common questions)
- **AND** pages SHALL include searchable keywords

---

### Requirement: README Simplification

The README SHALL serve as entry point, not comprehensive documentation.

#### Scenario: README contains essential sections only

- **WHEN** first-time visitor views README
- **THEN** README SHALL contain:
  - Problem statement (why DotRun exists)
  - 30-second demo (install → create → run)
  - Before/After comparison
  - Why DotRun? (vs alternatives)
  - Key Features (bullet list, ≤ 5 items)
  - Quick Start (≤ 30 lines)
  - Core Workflow (5-step process)
  - Documentation links section
  - Requirements (OS, shell, dependencies)
- **AND** README total length SHALL NOT exceed 250 lines

#### Scenario: Detailed content moved to wiki

- **WHEN** README is simplified
- **THEN** detailed content SHALL move to wiki:
  - Command organization (77 lines) → API-Reference.md
  - Collections system (178 lines) → Collection-Management-Advanced.md
  - Update workflow → Collection-Management-Advanced.md
  - Private repo support → Collection-Management-Advanced.md
  - Team workflow examples → Team-Workflows.md
  - Collection metadata format → Collection-Authoring.md
  - Real-world examples → User-Guide.md
  - Popular use cases → Use-Cases.md (new page)
- **AND** README SHALL link to relevant wiki pages
- **AND** no content SHALL be lost during migration

---

### Requirement: Wiki Content Accuracy for v3.0.0

The wiki SHALL reflect current v3.0.0 implementation without v2.x references.

#### Scenario: Command name consistency

- **WHEN** wiki references CLI commands
- **THEN** wiki SHALL use `dr` command name consistently
- **AND** wiki SHALL NOT reference `drun` (old name)
- **AND** examples SHALL use `dr scriptname` format

#### Scenario: Collection format accuracy

- **WHEN** wiki documents collections
- **THEN** wiki SHALL reference `dotrun.collection.yml` metadata file
- **AND** wiki SHALL NOT reference `.drun-collection.yml` (old format)
- **AND** metadata schema SHALL match current implementation:
  - Required fields: name, version, description, author, repository
  - Optional fields: license, homepage, dependencies

#### Scenario: Collection architecture accuracy

- **WHEN** wiki explains collections
- **THEN** wiki SHALL document copy-based architecture (not symlinks)
- **AND** wiki SHALL explain SHA256 hash tracking for modification detection
- **AND** wiki SHALL document interactive conflict resolution workflow
- **AND** wiki SHALL explain 8-character hash truncation

#### Scenario: Version reference accuracy

- **WHEN** wiki references features or versions
- **THEN** wiki SHALL reference v3.0.0 or later
- **AND** wiki SHALL NOT reference v2.0.0 features as current
- **AND** migration guide SHALL clearly distinguish v2.x from v3.0 behavior

---

### Requirement: loadHelpers System Documentation

The wiki SHALL comprehensively document the helper loading system.

#### Scenario: Architecture documentation

- **WHEN** user learns about helpers
- **THEN** Helper-System.md SHALL document:
  - 5-level specificity matching (absolute, exact, with-extension, path, filename)
  - Pattern examples for each level
  - Collection scope loading (`@collection-name`)
  - List mode for previewing matches (`--list`)
  - Environment modes (verbose, quiet)
- **AND** Architecture-Overview.md SHALL include helper system design

#### Scenario: Security features documented

- **WHEN** advanced user reviews security
- **THEN** Helper-System.md SHALL document:
  - Path traversal prevention (canonical path validation)
  - Circular dependency detection (depth limit of 10)
  - De-duplication tracking (loaded helpers map)
  - Allowed directory enforcement ($DR_CONFIG/helpers)
- **AND** each security feature SHALL include code example

#### Scenario: Collection author guidelines

- **WHEN** collection author uses helpers
- **THEN** Collection-Authoring.md SHALL document:
  - Loading loadHelpers function in scripts
  - Using flexible patterns for helper loading
  - Best practices for specificity (prefer collection-qualified paths)
  - Testing helper loading with --list
  - Avoiding circular dependencies
- **AND** guide SHALL include complete example script

#### Scenario: Troubleshooting helper loading

- **WHEN** user encounters helper loading errors
- **THEN** Helper-System.md SHALL document common errors:
  - "No helpers found matching 'pattern'" - causes and solutions
  - "Maximum helper loading depth exceeded" - circular dependency fix
  - "Multiple helpers matched" - specificity improvement
  - "Helper outside allowed directory" - security violation explanation
- **AND** FAQ.md SHALL link to Helper-System troubleshooting

---

### Requirement: Alias and Config File-Based Workflow

The wiki SHALL document file-based workflow for aliases and configs (v3.0 change).

#### Scenario: File-based workflow documentation

- **WHEN** user manages aliases
- **THEN** Alias-Management.md SHALL document:
  - Creating alias files with `dr aliases set NN-category`
  - File format: one file contains multiple aliases
  - Editing files (opens $EDITOR)
  - Reloading with `dr aliases reload`
  - Listing files with `dr aliases list`
- **AND** Configuration-Management.md SHALL document equivalent config workflow

#### Scenario: Numbered prefix convention

- **WHEN** user organizes alias/config files
- **THEN** guides SHALL document NN-category naming:
  - Format: `NN-category.aliases` or `NN-category.config`
  - NN: Two-digit number (01-99) controls load order
  - category: Descriptive name (git, docker, paths, api)
  - Examples: 01-git.aliases, 02-docker.aliases, 01-paths.config
- **AND** guides SHALL explain load order dependencies (e.g., PATH before tools)

#### Scenario: Migration from v2.x

- **WHEN** 2.x user upgrades
- **THEN** Migration-v3.0.md SHALL document workflow changes:
  - v2.x: `dr alias set git/gc "git commit"`
  - v3.0: `dr aliases set git` (creates file, edit interactively)
  - Rationale: File-based enables multiple aliases per file, easier management
- **AND** FAQ.md SHALL address migration questions

---

### Requirement: Zsh Completion UX Documentation

The wiki SHALL document Zsh completion's namespace-based organization and color scheme.

#### Scenario: Namespace organization

- **WHEN** Zsh user explores tab completion
- **THEN** Developer-Experience.md SHALL document tier system:
  - Tier 1 (Primary): `dr <tab>` shows folders, scripts, special commands, hint
  - Tier 2 (Namespaced): `dr -s <tab>` shows script management commands
  - Tier 2 (Namespaced): `dr -a <tab>` shows alias management commands
  - Tier 2 (Namespaced): `dr -c <tab>` shows config management commands
  - Tier 2 (Namespaced): `dr -col <tab>` shows collection management commands
- **AND** guide SHALL explain dual interface (flag vs subcommand style)

#### Scenario: Color scheme documentation

- **WHEN** user sees colored completions
- **THEN** Developer-Experience.md SHALL document color meanings:
  - Green: Special commands and script management
  - Yellow: Folders (with trailing /)
  - Cyan: Script names (without .sh extension)
  - Purple: Alias management subcommands
  - Red: Config management subcommands
  - Dark Gray: Hint text for namespace discovery
- **AND** guide SHALL explain hierarchical navigation (dr folder/subfolder/<tab>)

---

### Requirement: Collection Management User Documentation

The wiki SHALL document collections from user perspective (install, update, sync).

#### Scenario: Installing collections

- **WHEN** user installs collection
- **THEN** Collection-Management.md SHALL document:
  - Public repository: `dr -col add https://github.com/user/repo.git`
  - Private repository: `dr -col add git@github.com:user/repo.git` (SSH)
  - Interactive resource browser for selection
  - Hash tracking for modification detection
  - Tracking in collections.conf file
- **AND** guide SHALL include screenshots or ASCII examples

#### Scenario: Updating collections with conflicts

- **WHEN** user updates collection
- **THEN** Collection-Management.md SHALL document conflict resolution:
  - Unmodified files (hash matches): Update/Diff/Skip options
  - Modified files (hash differs): Keep/Overwrite/Diff/Backup options
  - New files (in collection, not imported): Import/View/Skip options
- **AND** guide SHALL explain hash-based modification detection
- **AND** guide SHALL include decision tree for conflict choices

#### Scenario: Syncing collections

- **WHEN** user checks for updates
- **THEN** Collection-Management.md SHALL document:
  - `dr -col sync` checks all collections for updates
  - Git fetch and tag comparison
  - Output shows available version updates
  - Link to update workflow documentation
- **AND** guide SHALL recommend sync frequency (weekly)

#### Scenario: Private repository authentication

- **WHEN** user accesses private collection
- **THEN** Collection-Management.md SHALL document:
  - SSH key setup for GitHub
  - Testing authentication: `ssh -T git@github.com`
  - Configuring ssh-agent
  - Troubleshooting authentication failures
- **AND** guide SHALL link to GitHub SSH documentation

---

### Requirement: Collection Authoring Documentation

The wiki SHALL document collection creation and distribution from author perspective.

#### Scenario: Collection initialization

- **WHEN** author creates collection
- **THEN** Collection-Authoring.md SHALL document:
  - Using `dr -col init` to create metadata skeleton
  - Required directory structure (scripts/, aliases/, helpers/, configs/)
  - Editing dotrun.collection.yml metadata
  - Required metadata fields (name, version, description, author, repository)
  - Optional metadata fields (license, homepage, dependencies)
- **AND** guide SHALL provide complete example collection

#### Scenario: Metadata specification

- **WHEN** author writes metadata
- **THEN** Collection-Authoring.md SHALL specify format:
  - name: Unique identifier (alphanumeric, dashes, underscores)
  - version: Semantic version (X.Y.Z) matching git tag
  - description: One-line summary
  - author: Creator or organization
  - repository: GitHub URL (HTTPS or SSH)
  - license: SPDX identifier (MIT, Apache-2.0, etc.)
  - homepage: Documentation URL (optional)
  - dependencies: List of required collections (optional)
- **AND** guide SHALL explain version synchronization with git tags

#### Scenario: Versioning and tagging

- **WHEN** author releases version
- **THEN** Collection-Authoring.md SHALL document:
  - Semantic versioning: MAJOR.MINOR.PATCH
  - MAJOR: Breaking changes, incompatible updates
  - MINOR: New features, backward compatible
  - PATCH: Bug fixes, no new features
  - Git tag format: `v1.0.0` or `1.0.0` (both valid)
  - Metadata version format: `1.0.0` (no v prefix)
  - Tag and metadata MUST synchronize
- **AND** guide SHALL include release workflow example

#### Scenario: Testing collections

- **WHEN** author tests collection
- **THEN** Collection-Authoring.md SHALL document:
  - Local testing: `dr -col add /path/to/collection`
  - Validation workflow before publishing
  - Testing installation, resource selection, updates
  - Verifying metadata with `dr -col list`
- **AND** guide SHALL provide validation checklist

---

### Requirement: FAQ Comprehensive Coverage

The FAQ SHALL address common questions organized by category.

#### Scenario: Installation and setup questions

- **WHEN** user encounters installation issues
- **THEN** FAQ.md SHALL answer:
  - "Installation failed with permission error" - chmod, sudo considerations
  - "How do I upgrade from v2.x to v3.x?" - link to Migration-v3.0.md
  - "Shell integration not working after install" - sourcing ~/.drrc
  - "Tab completion not appearing" - shell-specific troubleshooting
  - "EDITOR not set error" - setting $EDITOR in shell config
- **AND** each answer SHALL link to detailed guide section

#### Scenario: Scripts questions

- **WHEN** user has script questions
- **THEN** FAQ.md SHALL answer:
  - "How do I create my first script?" - dr set workflow
  - "Can I organize scripts in folders?" - folder hierarchy
  - "How do I document scripts with DOC tokens?" - ### DOC format
  - "Script not found but I just created it" - permissions, .sh extension
  - "Helper loading fails" - loadHelpers troubleshooting
- **AND** answers SHALL include example commands

#### Scenario: Aliases and configs questions

- **WHEN** user has alias/config questions
- **THEN** FAQ.md SHALL answer:
  - "What's the difference between scripts and aliases?" - execution vs sourcing
  - "How do aliases differ in v3.0 vs v2.x?" - file-based workflow change
  - "What is the NN-category naming convention?" - load order control
  - "How do I control load order?" - numbered prefix examples
  - "Why aren't my configs loading?" - shell restart required
- **AND** answers SHALL reference migration guide for 2.x users

#### Scenario: Collections questions

- **WHEN** user has collection questions
- **THEN** FAQ.md SHALL answer:
  - "What are collections and do I need them?" - use cases
  - "How do I install a private collection?" - SSH authentication
  - "What happens when I update a collection?" - conflict resolution
  - "Can I modify imported collection scripts?" - yes, with hash tracking
  - "Collection sync failing with git errors" - network, auth troubleshooting
  - "What is SHA256 hash tracking?" - modification detection explanation
  - "Old collection format vs new format" - .drun-collection.yml → dotrun.collection.yml
- **AND** answers SHALL link to Collection-Management.md sections

#### Scenario: Advanced topic questions

- **WHEN** power user has advanced questions
- **THEN** FAQ.md SHALL answer:
  - "How do I use helpers in my scripts?" - loadHelpers basics
  - "What is loadHelpers and how does it work?" - 5-level specificity
  - "Can I integrate DotRun with CI/CD?" - link to CI-CD-Integration.md
  - "How do I share scripts with my team?" - collections workflow
  - "Performance issues with large script libraries" - optimization tips
- **AND** answers SHALL link to Advanced Topics guides

---

### Requirement: Migration Guide Accessibility

The MIGRATION-v3.0.md guide SHALL be discoverable via wiki navigation.

#### Scenario: Migration guide moved to wiki

- **WHEN** MIGRATION-v3.0.md is moved
- **THEN** file SHALL move from repository root to ~/dotrun.wiki/Migration-v3.0.md
- **AND** content SHALL remain unchanged (597 lines preserved)
- **AND** Home.md SHALL link to Migration-v3.0.md in "Getting Started" section
- **AND** FAQ.md SHALL reference migration guide for v2.x questions
- **AND** README.md SHALL link to migration guide in "Get Started" section

#### Scenario: Upgrade path documentation

- **WHEN** 2.x user upgrades
- **THEN** Migration-v3.0.md SHALL document:
  - Breaking changes (aliases workflow, configs workflow, collection format)
  - Step-by-step upgrade instructions
  - Backward compatibility notes
  - Troubleshooting common upgrade issues
  - Examples of before/after workflows
- **AND** guide SHALL include "Quick Migration" checklist at top

---

### Requirement: Cross-Referencing System

Documentation pages SHALL link to related content for navigation.

#### Scenario: Bidirectional linking

- **WHEN** user navigates documentation
- **THEN** each wiki page SHALL include "See Also" section
- **AND** "See Also" SHALL link to 2-5 related pages
- **AND** README SHALL link to all primary wiki pages in "Documentation" section
- **AND** FAQ answers SHALL link to relevant detailed guides
- **AND** detailed guides SHALL reference FAQ for common questions

#### Scenario: Breadcrumb navigation

- **WHEN** user views wiki page
- **THEN** page SHALL include breadcrumb trail at top:
  - Format: Home > Section > Page
  - Example: Home > User Guides > Script Management
  - Links SHALL be clickable to parent sections
- **AND** breadcrumbs SHALL provide clear location context

#### Scenario: Consistent anchor format

- **WHEN** pages link to sections
- **THEN** anchor links SHALL use consistent format:
  - Lowercase words separated by hyphens
  - Example: `#creating-your-first-script`
  - GitHub auto-generated format preferred
- **AND** cross-references SHALL use full URLs or relative paths

---

### Requirement: Example Code Validation

All code examples SHALL match current implementation and be executable.

#### Scenario: Code examples tested

- **WHEN** documentation includes code examples
- **THEN** examples SHALL be tested against current v3.0.0 implementation
- **AND** examples SHALL use correct command names (`dr` not `drun`)
- **AND** examples SHALL use correct file formats (dotrun.collection.yml)
- **AND** examples SHALL include expected output or result
- **AND** shell syntax SHALL be valid and executable

#### Scenario: Example consistency

- **WHEN** multiple pages show similar examples
- **THEN** examples SHALL be consistent across pages
- **AND** variable names SHALL follow same conventions
- **AND** command flags SHALL use same style
- **AND** output formatting SHALL be consistent

---

### Requirement: Search and Discoverability

Documentation SHALL be optimized for search and navigation.

#### Scenario: Page metadata

- **WHEN** wiki page is created or updated
- **THEN** page SHALL include:
  - Clear title (descriptive, under 50 characters)
  - Description paragraph (first paragraph summarizes content)
  - Keywords for search (alternative terms, synonyms)
  - Category tags where applicable
- **AND** metadata SHALL help GitHub wiki search

#### Scenario: Topic index

- **WHEN** user needs alphabetical reference
- **THEN** Home.md or separate Index.md SHALL provide:
  - Alphabetical list of topics
  - Brief description per topic
  - Link to relevant page and section
- **AND** index SHALL cover all major topics

---

## MODIFIED Requirements

### Requirement: Collection Metadata Format (Modified from collections spec)

The collection metadata format SHALL use the new file name and schema.

#### Scenario: Metadata file name (MODIFIED)

- **WHEN** collection is created
- **THEN** metadata file SHALL be named `dotrun.collection.yml` (NOT `.drun-collection.yml`)
- **AND** file SHALL be in repository root
- **AND** alternative extension `.yaml` SHALL also be accepted

#### Scenario: Required metadata fields (MODIFIED)

- **WHEN** metadata is validated
- **THEN** required fields SHALL be:
  - name: Collection identifier (alphanumeric, dashes, underscores)
  - version: Semantic version (X.Y.Z format)
  - description: One-line summary (under 200 characters)
  - author: Creator name or organization
  - repository: Git repository URL (HTTPS or SSH)
- **AND** missing required fields SHALL cause validation error

#### Scenario: Optional metadata fields (ADDED to existing requirement)

- **WHEN** metadata includes optional fields
- **THEN** optional fields MAY include:
  - license: SPDX license identifier (e.g., MIT, Apache-2.0)
  - homepage: Documentation website URL
  - dependencies: Array of required collection names
- **AND** invalid optional fields SHALL be ignored with warning

---

## REMOVED Requirements

None. This is a new capability with no removed requirements.
