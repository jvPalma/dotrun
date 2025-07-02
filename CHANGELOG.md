# Changelog

All notable changes to DotRun will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-12-30

### Added
- **Script Organization System**: Complete move/rename functionality for script management
  - `drun move <source> <destination>` - Move and rename scripts with full flexibility
  - `drun rename <source> <destination>` - Alias for move command
  - `drun mv <source> <destination>` - Short alias for move command
- **Advanced Move Scenarios**:
  - Simple rename: `oldName` → `newName`
  - Move to folder: `script` → `folder/script`
  - Move between folders: `folderA/script` → `folderB/script`
  - Rename and move: `oldName` → `folderC/newName`
- **Intelligent File Management**:
  - Automatic movement of both script (.sh) and documentation (.md) files
  - Smart directory creation for destination paths
  - Automatic cleanup of empty source directories
  - Preservation of file permissions and executable status
- **Content Updates**:
  - Automatic update of script name references in documentation
  - Update of inline DOC sections with new script names
  - Update of usage examples in documentation files
- **Safety Features**:
  - Comprehensive input validation (invalid characters, path traversal)
  - Conflict detection (prevents overwriting existing scripts)
  - Permission validation before attempting moves
  - Circular move prevention
- **Aliases Management System**: Complete shell alias management
  - `drun aliases init` - Initialize aliases system
  - `drun aliases add <name> <command>` - Add new aliases with category support
  - `drun aliases list` - List all aliases with category filtering
  - `drun aliases edit <name>` - Edit existing aliases
  - `drun aliases remove <name>` - Remove aliases with confirmation
  - `drun aliases reload` - Reload aliases in current shell
- **Aliases Features**:
  - Category organization (git, docker, system, development, custom)
  - Cross-shell compatibility (bash, zsh, fish)
  - Input validation and reserved keyword checking
  - Shell integration with automatic sourcing
- **Global Configuration System**: Environment variables and config management
  - `drun config init` - Initialize configuration system
  - `drun config set <key> <value>` - Set configuration values with category support
  - `drun config get <key>` - Get configuration values with masking
  - `drun config list` - List configurations with category filtering
  - `drun config edit <key>` - Edit existing configurations
  - `drun config unset <key>` - Remove configuration values
  - `drun config reload` - Reload configuration in current shell
- **Configuration Features**:
  - Category organization (api, dev, personal, cloud, database)
  - Secure storage for sensitive values (API keys, tokens)
  - Automatic value masking for security
  - Shell integration for system-wide environment variables
  - File permission security (600/700 modes)
- **Enhanced Shell Completion**:
  - Tab completion for move/rename commands in bash, zsh, and fish
  - Source script completion for first argument
  - Destination suggestions including existing folders and scripts
  - Full completion support for aliases and config commands
  - Category completion and value suggestions

### Enhanced
- **Documentation System**: 
  - Enhanced help output with move/rename examples
  - Complete professional documentation overhaul
  - Streamlined README.md from 598 to 172 lines with clear problem/solution focus
  - Restructured wiki documentation with 13 comprehensive pages
  - Added missing essential pages (FAQ, Migration Guide, Quick Reference, Architecture Overview)
  - Improved navigation with breadcrumbs and cross-references
  - Created role-based learning paths for different user types
- **Error Handling**: Improved error messages with actionable guidance for move operations
- **User Experience**: 
  - Clear success messages with step-by-step operation feedback
  - Professional presentation throughout documentation
  - 30-second demo for immediate value demonstration
  - Clear differentiation from alternatives (make, npm scripts, shell aliases)

## [1.0.1] - 2024-12-30

### Features Present in v1.0.1

#### Core Script Management
- **Script Creation**: `drun add <name>` - Create new scripts with automatic skeleton generation
- **Script Editing**: `drun edit <name>` - Edit scripts in preferred editor with VS Code/nano detection
- **Script Execution**: `drun <scriptname>` - Execute scripts from anywhere with nested folder support
- **Script Discovery**:
  - `drun -l` - List all scripts (names only)
  - `drun -L` - List scripts with embedded documentation
  - Tree-style colorized output with emoji enhancement
  - Scoped listing within specific folders

#### Documentation System
- **Inline Documentation**: `### DOC` token system for embedding help in scripts
- **Help Display**: `drun help <name>` - Show embedded script documentation
- **Markdown Documentation**:
  - `drun edit:docs <name>` - Edit full markdown documentation
  - `drun docs <name>` / `drun details <name>` - Render markdown docs with glow
  - Automatic documentation file creation and management

#### Development Environment Integration
- **Code Quality**: ShellCheck integration for bash script linting with configurable rules
- **Editor Integration**: Automatic detection and launching of preferred editors
- **Cross-Platform Support**: Linux, macOS, Windows (WSL/Git Bash/Cygwin), BSD compatibility

#### Configuration and Setup
- **Flexible Configuration**: 
  - `DRUN_CONFIG` environment variable support
  - XDG Base Directory specification compliance
  - Default location: `~/.config/dotrun`
- **Directory Management**: Automatic creation of required directory structure
- **Comprehensive Installer**:
  - One-liner installation via curl
  - Custom installation directory support
  - Shell integration setup with completion scripts
  - Framework update system preserving user scripts

#### Shell Integration
- **Multi-Shell Completion**: Native completion for bash, zsh, and fish shells
- **Smart Completion**: Tab completion for commands, scripts, and folder navigation
- **Shell Detection**: Intelligent shell environment detection and configuration

#### Collection Management
- **Script Collections**:
  - `drun import <url|path>` - Import script collections from git repositories
  - `drun import --preview` - Preview collections before importing
  - `drun import --pick <script>` - Import specific scripts selectively
  - `drun export <name> <path>` - Export collections to directories
  - `drun collections list` - List all installed collections
  - `drun collections remove <name>` - Remove collections cleanly
- **Collection Features**:
  - YAML metadata support (`.drun-collection.yml`)
  - Automatic collection validation and namespace isolation
  - Documentation preservation during operations

#### Team Collaboration
- **Team Integration**:
  - `drun team init <repo-url>` - Setup team script repositories
  - Team script sharing and synchronization capabilities
- **YADM Integration**:
  - `drun yadm-init` - Setup DotRun with existing yadm dotfiles
  - Symlink management and git ignore configuration

#### Helper System
- **Modular Libraries**:
  - `helpers/pkg.sh` - Package manager detection and utilities
  - `helpers/git.sh` - Git repository helpers and navigation
  - `helpers/lint.sh` - Code linting utilities
  - `helpers/collections.sh` - Collection management functions
  - `helpers/filters.sh` - Content filtering utilities
  - `helpers/constants.sh` - Shared constants and configuration
- **Utility Functions**:
  - Cross-platform package installation hints
  - Language detection from file extensions
  - File validation and permission checking

#### User Experience
- **Interactive Interface**:
  - Colorized output with consistent theming
  - Progress indicators and comprehensive status messages
  - User confirmation prompts for destructive operations
- **Help System**:
  - `drun --help` - Comprehensive help with usage examples
  - `drun --version` - Version information display
  - Integration guidance and setup instructions

#### Example Scripts Collection
- **AI/ML Tools**: aiCommit (AI-powered commit messages), gpt (codebase analysis), prDescription
- **Code Quality**: codeCheck (comprehensive code analysis)
- **Git Workflow**: branchCleanup, branchSlice, prStack, prStats (PR analytics)
- **React Development**: Component generators, hook templates, testing utilities
- **Workstation Management**: Workspace setup and maintenance scripts
- **Complete Documentation**: Comprehensive docs for all example scripts

### Architecture
- **Separation of Concerns**: Clean separation between framework and user scripts
- **Version Control Integration**: Git-first approach for script management and sharing
- **Extensible Design**: Modular helper system for easy feature additions
- **Documentation-Driven**: Every script includes inline help and markdown documentation

---

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/joaopalma/dotrun/master/install.sh | bash
```

## Upgrade Instructions

### To v2.0.0
The new version is fully backward compatible. Simply run the installer to upgrade:

```bash
curl -sSL https://raw.githubusercontent.com/joaopalma/dotrun/master/install.sh | bash
```

Your existing scripts and collections will be preserved. The new move/rename functionality will be immediately available after upgrade.