# DotRun Examples Collection

A comprehensive collection of example scripts demonstrating DotRun's capabilities across different development domains. This collection serves as both a learning resource and a practical toolkit for developers.

## Quick Start

Import this collection to try out DotRun's features:

```bash
# Import the examples collection
drun import https://github.com/jvPalma/dotrun.git examples

# List available example scripts
drun -L examples/

# Try the codebase structure analyzer
drun examples/ai/gpt .

# Generate AI commit messages
drun examples/ai/aiCommit

# Create AI-powered PR descriptions
drun examples/ai/prDescription

# Try the interactive Git branch cleanup
drun examples/git/branchCleanup

# Create a new React component
drun examples/react/rnewc MyComponent
```

## Available Scripts

### 🤖 AI Development Tools

- **`ai/gpt`** - Generate codebase structure analysis reports
  - Scans directories, creates project summaries with language histograms
  - Integrates with `cloc` for detailed analysis
  - Perfect for understanding project structure and feeding to analysis tools

- **`ai/aiCommit`** - AI-generated conventional commit messages
  - Uses intelligent analysis to understand staged changes
  - Generates clear, conventional commit messages
  - Saves time on repetitive commit message writing

- **`ai/prDescription`** - AI-powered pull request descriptions
  - Analyzes git diff and generates PR titles and bodies
  - Uses contextual information for meaningful descriptions
  - Integrates with GitHub workflow

### 🌿 Git Workflow Automation

- **`git/branchCleanup`** - Interactive branch management and cleanup
  - Intelligent detection of merged and squash-merged branches
  - Safe deletion with stash management
  - Rich CLI interface with emoji indicators

- **`git/branchSlice`** - Create focused, atomic commits
  - Interactive staging of specific changes
  - Helps maintain clean Git history

- **`git/branchCoSliced`** - Combine related branch slices
  - Merge split work back together
  - Maintains commit granularity

- **`git/branchGetSlicedCode`** - Extract specific changes
  - Retrieve targeted modifications
  - Useful for cherry-picking features

- **`git/prStack`** - PR stacking and management
  - Manage stacked pull requests
  - Handle complex feature development workflows

- **`git/prStats`** - Pull request statistics
  - Analyze PR metrics and performance
  - Track development team efficiency

### ⚛️ React Development Utilities

- **`react/rnewc`** - Create React component scaffolds
  - Generates component, test, and index files
  - Follows modern React patterns

- **`react/rnewh`** - Create custom React hooks
  - Hook template with TypeScript support
  - Includes test boilerplate

- **`react/rnewhp`** - Create React hook with props
  - Extended hook template for complex scenarios
  - Parameter-aware hook generation

- **`react/testAll`** - Comprehensive React testing
  - Run all test suites with coverage
  - Integrated linting and type checking

### 🔍 Code Quality Tools

- **`code/codeCheck`** - Code quality analysis and checks
  - Comprehensive code quality assessment
  - Integration with linting and analysis tools
  - Automated code review assistance

### 🖥️ Workstation Management

- **`workstation/wsc`** - Configure development workstation
  - Cross-platform setup automation
  - Install essential development tools

- **`workstation/wss`** - Setup development environment
  - Environment-specific configurations
  - Project template initialization

- **`workstation/wsl`** - Linux subsystem setup
  - Windows WSL configuration
  - Ubuntu/Debian development environment

- **`workstation/wstp`** - Workstation template processor
  - Template-based configuration management
  - Customizable setup workflows

## Features

### 🎯 **Interactive Interfaces**
Most scripts include rich CLI interfaces with:
- Emoji indicators for visual clarity
- Interactive selection menus
- Progress feedback and confirmations
- Graceful error handling

### 🛡️ **Safety First**
All scripts follow safety best practices:
- Confirmation prompts for destructive operations
- Automatic stashing of uncommitted changes
- Graceful interruption handling (Ctrl+C)
- Detailed operation summaries

### 📚 **Comprehensive Documentation**
Each script includes:
- Detailed README with examples
- Inline help and usage instructions
- Architecture documentation for complex scripts
- Troubleshooting guides

### 🔧 **Extensible Design**
Scripts are designed to be:
- Easily customizable for your needs
- Good templates for your own scripts
- Modular with shared helper functions
- Well-documented for learning

## Dependencies

### Required
- `bash` (4.0+)
- `git` (2.0+)

### Optional (enhances functionality)
- `cloc` - For detailed language analysis (codebase scripts)
- `jq` - For JSON processing
- `docker` - For containerized workstation tools
- `node` & `npm` - For React development scripts

## Usage Examples

### Example 1: AI-Powered Development

```bash
# Generate comprehensive codebase analysis
drun examples/ai/gpt /path/to/project

# Generate conventional commit messages
git add .
drun examples/ai/aiCommit

# Create PR descriptions
drun examples/ai/prDescription "Adding new feature"

# All output ready for analysis tools and GitHub
```

### Example 2: Clean Up Git Branches

```bash
# Interactive branch cleanup
drun examples/git/branchCleanup

# Features:
# - Visual branch categorization
# - Automatic squash-merge detection
# - Safe stash management
# - Batch local + remote deletion
```

### Example 3: React Development

```bash
# Create new component with tests
drun examples/react/rnewc components/Header

# Creates:
# - components/Header/Header.tsx
# - components/Header/Header.test.tsx
# - components/Header/index.ts
```

### Example 4: Workstation Setup

```bash
# Configure development environment
drun examples/workstation/wsc

# Installs and configures:
# - Essential development tools
# - Shell enhancements
# - Cross-platform compatibility
```

## Contributing

This collection welcomes contributions! To add new examples:

1. **Follow the pattern**: Look at existing scripts for structure
2. **Include documentation**: Add comprehensive README.md
3. **Add safety features**: Include confirmations and error handling
4. **Test thoroughly**: Ensure scripts work across different environments
5. **Update this README**: Document your new script

## Installation

### As a DotRun Collection

```bash
# Import from GitHub
drun import https://github.com/jvPalma/dotrun.git examples

# Use with namespace
drun examples/script-name
```

### Direct Clone

```bash
# Clone and use directly
git clone https://github.com/jvPalma/dotrun.git
cd dotrun/examples

# Run scripts directly
./bin/ai/gpt.sh /path/to/analyze
```

## Architecture

This collection follows DotRun's standard structure:

```
examples/
├── .drun-collection.yml        # Collection metadata
├── README.md                   # This file
├── bin/                        # Executable scripts
│   ├── ai/
│   ├── git/
│   ├── react/
│   └── workstation/
├── docs/                       # Documentation
│   ├── ai/
│   ├── git/
│   ├── react/
│   └── workstation/
└── helpers/                    # Shared utilities
    ├── bash-interactive-cleanup.sh
    └── workstation.sh
```

## License

MIT License - Feel free to use, modify, and share these examples.

## Support

- **Documentation**: Each script includes detailed documentation
- **Issues**: Report problems on the main DotRun repository
- **Community**: Share your own examples and improvements

---

*This collection demonstrates the power and flexibility of DotRun for team collaboration and personal productivity. Use these scripts as inspiration for building your own development toolkit!*