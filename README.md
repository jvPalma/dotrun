# DotRun — Developer Productivity Script Manager

[![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)](VERSION)

_Write once, run anywhere. Build your personal development toolkit._

DotRun is a Git-backed, shell-agnostic script manager designed for developers who want to streamline their workflow with reusable, well-documented scripts. It lives in `$XDG_CONFIG_HOME/dotrun` _(defaults to `~/.config/dotrun`)_ and puts a single `drun` command on your `PATH`.

## ✨ Features

- 🚀 **Fast Script Access** - Run any script with `drun scriptname` or `drun category/scriptname`
- 📚 **Built-in Documentation** - Markdown docs alongside every script
- 🔍 **Smart Discovery** - Tree-view listing with descriptions
- 🧹 **Automatic Linting** - ShellCheck integration for bash scripts
- 🔗 **Git Integration** - Version control your scripts like code
- 🎯 **Interactive Tools** - Rich CLI interfaces with colors and emojis

---

## 🚀 Quick Install

### One-liner Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

### Custom Installation Location

```bash
DOTRUN_BIN_DIR="$HOME/.local/bin" \
  bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

### Manual Installation (Clone & Install)

```bash
git clone https://github.com/jvPalma/dotrun
cd dotrun/
./install.sh
```

The installer will:

1. 📂 **Copy framework files** to `~/.config/dotrun/`
   - `helpers/` → Core utility libraries
   - `drun_completion.*` → Shell completion files
2. 🔗 **Install binary** `drun` to `~/.local/bin/` (or custom `DOTRUN_BIN_DIR`)
3. 📁 **Create user directories** for your personal scripts:
   - `~/.config/dotrun/bin/` - Your executable scripts
   - `~/.config/dotrun/docs/` - Your script documentation
   - `~/.config/dotrun/collections/` - Team script collections
4. 🎨 **Set up shell completion** (Bash/Zsh/Fish)
5. ✅ **Verify installation** and show next steps

**Note**: The original repository stays separate - only necessary framework files are copied to your config directory.

📖 **For detailed installation information, see [Installation Guide](./docs/installation-guide.md)**.

### Manual Shell Completion Setup

If you're using Zsh or Fish, you can enable enhanced completion by adding the appropriate completion file:

**Zsh:**

```bash
# Add to ~/.zshrc
source ~/.config/dotrun/drun_completion.zsh
```

**Fish:**

```bash
# Copy to Fish completions directory
cp ~/.config/dotrun/drun_completion.fish ~/.config/fish/completions/drun.fish
```

**Bash:**

```bash
# Add to ~/.bashrc
source ~/.config/dotrun/drun_completion.bash
```

**Note:** The installer automatically sets up completion for your detected shell via the `.drunrc` file.

### Framework Updates

To update DotRun framework files while preserving your personal scripts:

```bash
# Navigate to original repository
cd /path/to/original/dotrun
git pull origin master

# Update framework files (use --force to overwrite)
./install.sh --force
```

This updates:

- Core helper libraries in `~/.config/dotrun/helpers/`
- Shell completion files
- The `drun` binary

**Your personal scripts in `bin/`, `docs/`, and `collections/` remain untouched.**

---

## 📁 File Structure & Installation Layout

### Repository Structure (Original Clone)

The DotRun repository contains the framework and reference files:

```
~/.config/dotrun/
├── bin/                      # 🎯 Executable scripts organized by category
├── helpers/                  # 📚 Shared utility libraries
├── docs/                     # 📖 Comprehensive documentation
├── drun_completion.bash      # 🎨 Bash completion script
├── drun_completion.zsh       # 🎨 Zsh completion script
└── drun_completion.fish      # 🎨 Fish completion script
```

### User Configuration Structure (After Installation)

Your personal DotRun configuration lives in `~/.config/dotrun/`:

```
~/.config/dotrun/             # Your personal DotRun workspace
├── bin/                      # 🎯 YOUR personal executable scripts
│   ├── git/                  # Organized by category
│   ├── react/
│   ├── docker/
│   └── hello.sh              # Example script (clean installs only)
├── docs/                     # 📖 YOUR script documentation
│   └── hello.md              # Example docs (clean installs only)
├── helpers/                  # 📚 Core helper libraries (from repo)
│   ├── constants.sh          # ← Copied from repository
│   ├── filters.sh            # ← Copied from repository
│   ├── git.sh                # ← Copied from repository
│   ├── lint.sh               # ← Copied from repository
│   ├── pkg.sh                # ← Copied from repository
│   └── collections.sh        # ← Copied from repository
├── collections/              # 👥 Team script collections
│   ├── devops-tools/         # Example: imported team collection
│   └── frontend-utils/       # Example: imported team collection
├── drun_completion.bash      # 🎨 Bash completion (from repo)
├── drun_completion.zsh       # 🎨 Zsh completion (from repo)
└── drun_completion.fish      # 🎨 Fish completion (from repo)
```

### Installation Process

The `install.sh` script performs these file operations:

1. **Framework Files (Copied from repo → user config)**:

   - `helpers/` → `~/.config/dotrun/helpers/`
   - `drun_completion.*` → `~/.config/dotrun/`

2. **Binary Installation**:

   - `drun` → `~/.local/bin/drun` (or custom `DOTRUN_BIN_DIR`)

3. **User Directories (Created during installation)**:

   - `~/.config/dotrun/bin/` - For your personal scripts
   - `~/.config/dotrun/docs/` - For your script documentation
   - `~/.config/dotrun/collections/` - For team script collections

4. **Reference Files (NOT copied)**:
   - `examples/` - View in original repo for inspiration
   - `template/` - Reference for creating new scripts
   - `README.md`, `docs/` - Documentation stays in original repo

### Why This Separation?

DotRun maintains clean separation between:

- **Framework** (original repo): Core functionality, examples, documentation
- **User Config** (`~/.config/dotrun/`): Your personal scripts and customizations
- **Team Collections** (`~/.config/dotrun/collections/`): Shared team scripts

**Benefits**:

- 📚 Keep original repository clean and updatable
- 📝 Your personal scripts stay separate from framework
- 👥 Team collections are isolated and shareable
- 🔄 Easy framework updates without affecting your work
- 💾 Backup/sync only what matters (your config directory)

---

## 🛠️ Advanced Features

### 🔍 Automatic Linting

- **ShellCheck Integration** - Automatic bash script validation
- **Pre-commit Hooks** - Lint before editing
- **Custom Rules** - Configurable linting standards

### 📦 Package Management

```bash
# Automatic package hints when dependencies are missing
$ drun git/branchCleanup
# "git not found - install with: sudo apt install git"
```

---

## 📖 Documentation System

Each script comes with comprehensive documentation:

- **Inline Help** - `### DOC` sections in scripts
- **Markdown Guides** - Detailed documentation in `docs/` (rendered with `glow`)
- **Usage Examples** - Real-world scenarios and workflows
- **Troubleshooting** - Common issues and solutions

```bash
drun help git/branchCleanup  # Shows inline ### DOC section (markdown rendering planned)
```

_Note: Full markdown documentation integration with `glow` is currently in development_

---

## 🎯 Example Shared Tools

#### `ai/gpt` - Generate an ready to share codebase report

- 📁 **Codebase Context** - Includes an tree section with how the files are organized
- 🎨 **File Extenstions** - Reports the number of files of each type to help with context sharing to the AI agent.
- 💾 **File Persistence** - Save the report in an .out file, for the user to review, and copy & paste

#### `git/branchCleanup` - Intelligent Branch Management

- ✅ **Smart Merge Detection** - Automatically identifies regular and squash-merged branches
- 🎨 **Visual Interface** - Color-coded branch status with emoji indicators
- 📦 **Stash Management** - Safely handles uncommitted changes
- 🌐 **Remote Cleanup** - Option to delete both local and remote branches
- 🛡️ **Safety Features** - Protected branches, graceful interruption handling

#### `git/branchSlice` - Precise Code Extraction

- 📂 **File/Directory Slicing** - Extract specific code with full git history
- 👥 **Co-authoring Support** - Preserve contributor attribution
- 🎯 **Smart Filtering** - Exclude build artifacts, dependencies automatically
- 📖 **Documentation Generation** - Auto-creates migration documentation

#### And much more here:

- [ai](./examples/ai/)
  - [gpt](./examples/ai/gpt/)
- [git](./examples/git/)
  - [branchCleanup](./examples/git/branchCleanup/)
  - [branchCoSliced](./examples/git/branchCoSliced/)
  - [branchGetSlicedCode](./examples/git/branchGetSlicedCode/)
  - [branchSlice](./examples/git/branchSlice/)
- [react](./examples/react/)
  - [rnewc](./examples/react/rnewc/)
  - [rnewh](./examples/react/rnewh/)
  - [rnewhp](./examples/react/rnewhp/)
  - [testAll](./examples/react/testAll/)
- [workstation](./examples/workstation/)
  - [wsc](./examples/workstation/wsc/)
  - [wsl](./examples/workstation/wsl/)
  - [wss](./examples/workstation/wss/)
  - [wstp](./examples/workstation/wstp/)

---

## 🌇 Some printscreens

<details>
<summary>How to use <code>drun</code> CLI </summary>

---

![Screenshot 2025-06-09 17 47 37](https://github.com/user-attachments/assets/8e2bed77-2450-4064-8393-8f30d438ddc2)

![Screenshot 2025-06-09 17 47 45](https://github.com/user-attachments/assets/797c0354-6def-47dd-966d-019164bb93e5)

![Screenshot 2025-06-09 17 48 04](https://github.com/user-attachments/assets/8a18b70f-bbd6-4cb0-8e36-9038a35dc513)

![Screenshot 2025-06-09 17 48 22](https://github.com/user-attachments/assets/f9c97c71-3044-4859-992b-b5ec766b08de)

![Screenshot 2025-06-09 17 48 27](https://github.com/user-attachments/assets/56b6b862-9bfd-4eea-9cc4-953db6b138e3)

![Screenshot 2025-06-09 17 49 04](https://github.com/user-attachments/assets/187f3fa5-05ce-47fd-8e0b-e514aefd6c4e)

![Screenshot 2025-06-09 17 49 15](https://github.com/user-attachments/assets/d870dc18-d2b8-4531-81e5-8cc1a12ad4a9)

---

</details>

## 📋 Requirements

### System Requirements

- **Unix-like OS** - Linux, macOS, Windows (WSL)
- **Bash 4.0+** - For script execution
- **Git** - For version control features

### Optional Dependencies

- **ShellCheck** - For bash script linting
- **glow** - For beautiful markdown documentation rendering
- **jq** - For JSON processing in some scripts
- **curl/wget** - For network operations

### Shell Support

- ✅ **Bash** - Full feature support
- ✅ **Zsh** - Complete compatibility
- ✅ **Fish** - Full support

---

## 🚀 Next Development

DotRun is designed to work seamlessly with your existing dotfile manager while maintaining clear separation:

### 🔗 yadm Integration

```bash
# Option 1: Add DotRun framework as submodule (recommended)
yadm submodule add https://github.com/jvPalma/dotrun .local/share/dotrun-framework
cd ~/.local/share/dotrun-framework
./install.sh

# Option 2: Include user config in dotfiles (after installation)
yadm add ~/.config/dotrun/bin/
yadm add ~/.config/dotrun/docs/
yadm add ~/.config/dotrun/collections/
yadm commit -m "Add personal DotRun scripts"
```

### 🎨 Shell Completion (In Progress)

```bash
# Include your personal DotRun config in chezmoi
chezmoi add ~/.config/dotrun/bin/
chezmoi add ~/.config/dotrun/docs/
chezmoi add ~/.config/dotrun/collections/

# Framework can be installed via chezmoi scripts
# Add to ~/.local/share/chezmoi/run_onchange_install-dotrun.sh
```

### 🌍 Cross-Platform Support (Planned)

```bash
# Add framework as submodule
git submodule add https://github.com/jvPalma/dotrun .local/share/dotrun-framework

# Symlink or copy your config directory
ln -s ~/.config/dotrun ~/dotfiles/.config/dotrun
```

### 🌟 Benefits of This Approach

- **Clean Separation**: Framework (updateable) vs your scripts (personal)
- **Easy Updates**: Update DotRun framework without affecting your work
- **Dotfile Integration**: Your `~/.config/dotrun/` can be managed by your dotfile manager
- **Team Collaboration**: Share collections without exposing personal configs
- **Portability**: Framework + personal config = complete environment
- **Version Control**: Track your scripts separately from the framework
- **No Conflicts**: Framework updates won't overwrite your customizations

---

## 🔧 Troubleshooting File Locations

### "Where is my script?"

- **Your scripts**: `~/.config/dotrun/bin/`
- **DotRun binary**: `~/.local/bin/drun` (or custom `DOTRUN_BIN_DIR`)
- **Framework helpers**: `~/.config/dotrun/helpers/`
- **Original repository**: Where you cloned it (separate from config)

### "How do I update the framework?"

```bash
# Go to original repository and update
cd /path/to/original/dotrun
git pull
./install.sh --force  # Updates framework files only
```

### "Where are the examples?"

- **Examples**: In the original repository at `examples/`
- **Not copied** to your config directory
- **View online**: [GitHub examples](https://github.com/jvPalma/dotrun/tree/master/examples)

### "How do I backup my scripts?"

```bash
# Backup your personal DotRun config
tar -czf dotrun-backup.tar.gz ~/.config/dotrun/

# Or use your dotfile manager
yadm add ~/.config/dotrun/
yadm commit -m "Backup DotRun scripts"
```

---

## 📄 License

MIT License - see LICENSE file for details.

---

**Happy scripting!** 🚀

_Built with ❤️ for developers who love automation_
