# DotRun

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell Support](https://img.shields.io/badge/shell-bash%20%7C%20zsh%20%7C%20fish-blue.svg)](#)

**Stop hunting for commands. Start running them.**

DotRun transforms scattered scripts, complex command sequences, and tribal knowledge into a unified, searchable, and shareable toolkit that works across all your projects.

## The Problem

Developers waste countless hours on repetitive tasks:
- **Searching Slack** for that deployment command someone shared last month
- **Copy-pasting** complex Git workflows from documentation
- **Re-creating** environment setup scripts for each new project
- **Remembering** which parameters go with which tools

You know the solution exists somewhere, but finding and using it is the hard part.

## The Solution

DotRun gives you instant access to any script from anywhere:

```bash
# Instead of this complexity...
git fetch --all && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d

# Just run this
drun git/cleanup
```

**One command replaces dozens of scattered scripts, aliases, and copy-paste workflows.**

## 30-Second Demo

Install and run your first script in 30 seconds:

```bash
# 1. Install DotRun
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

# 2. Create a script
drun add deploy

# 3. Run it from anywhere
cd ~/any-project && drun deploy
```

## Before vs After

**Before DotRun:**
```bash
# Deployment scattered across multiple places
grep -r "deploy" ~/.bash_history | tail -5
# Copy from Slack: docker build -t app . && docker push...
# Find that script: where did I put deploy.sh?
# Remember parameters: was it --env staging or --environment=staging?
```

**After DotRun:**
```bash
# Everything in one place, documented, and searchable
drun -L deploy          # List all deployment scripts
drun help deploy        # Show documentation
drun deploy staging     # Run with confidence
```

## Why DotRun?

**vs Individual Scripts:** Unified access, automatic documentation, team sharing
**vs Aliases:** Cross-shell support, parameter handling, self-documenting
**vs Makefiles:** Project-independent, globally accessible, language-agnostic
**vs README lists:** Executable, searchable, with built-in help

## Key Features

- **🚀 Instant Access** - Run any script with `drun scriptname` from anywhere
- **📚 Self-Documenting** - Every script includes usage examples and help text
- **👥 Team Sharing** - Import/export collections while keeping personal scripts separate
- **🔍 Smart Discovery** - Find scripts by name, category, or description
- **🐚 Shell Universal** - Works identically in Bash, Zsh, and Fish with tab completion

## Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

Installs to `~/.local/bin/drun` with workspace in `~/.config/dotrun/`

## Quick Start

### Create Your First Script
```bash
drun add hello
# Opens editor with documentation template
# Add: echo "Hello from anywhere!"
drun hello  # Run from any directory
```

### Import Examples Collection
```bash
drun import https://github.com/jvPalma/dotrun.git examples
drun -L examples/    # Browse 20+ ready-to-use scripts
drun examples/git/cleanup    # Clean up old Git branches
```

### Real-World Example
```bash
# Create a deployment script
drun add deploy/staging
# Add your deployment logic with parameters
# Document usage with ### DOC sections

# Now deploy from any project
cd ~/frontend-app && drun deploy/staging
cd ~/backend-service && drun deploy/staging
cd ~/mobile-app && drun deploy/staging
```

## Core Workflow

1. **Create:** `drun add scriptname` - Creates script with documentation template
2. **Document:** Add `### DOC` sections for usage examples and help
3. **Run:** `drun scriptname` - Execute from anywhere with tab completion
4. **Share:** `drun export collection` - Package scripts for team sharing
5. **Discover:** `drun -L` - Browse all scripts with descriptions

## Popular Use Cases

**Git Workflows:** Branch cleanup, PR creation, commit templates
**Deployment:** Environment-specific deployment with rollback
**Development:** Project setup, testing, code generation
**DevOps:** Server maintenance, monitoring, backup scripts
**AI Integration:** Commit messages, code review, documentation

## Documentation

All comprehensive guides are available in our wiki:

- [📖 Installation Guide](https://github.com/jvPalma/dotrun/wiki/Installation-Guide) - Detailed setup and customization
- [📖 User Guide](https://github.com/jvPalma/dotrun/wiki/User-Guide) - Complete feature walkthrough
- [📖 Script Development](https://github.com/jvPalma/dotrun/wiki/Script-Development) - Best practices and templates
- [📖 Team Collaboration](https://github.com/jvPalma/dotrun/wiki/Team-Workflows) - Sharing and collection management

## Examples Collection

Browse [real-world scripts](examples/) ready for immediate use:
- **AI Tools:** Commit messages, PR descriptions, code analysis
- **Git Workflows:** Branch management, PR stack creation
- **React Development:** Component generation, testing workflows
- **Workstation Management:** Environment switching, automation

## Requirements

- **OS:** Linux, macOS, Windows (WSL)
- **Shell:** Bash 4.0+, Zsh, or Fish
- **Dependencies:** Git (required), ShellCheck (optional), glow (optional)

## Get Started

1. [Install DotRun](https://github.com/jvPalma/dotrun/wiki/Installation-Guide)
2. [Import Examples](examples/) to see what's possible
3. [Create your first script](https://github.com/jvPalma/dotrun/wiki/User-Guide)
4. [Share with your team](https://github.com/jvPalma/dotrun/wiki/Team-Workflows)

---

**Transform your development workflow from scattered scripts to unified productivity.**

*Questions? [Open an issue](https://github.com/jvPalma/dotrun/issues) or check our [FAQ](https://github.com/jvPalma/dotrun/wiki/FAQ)*