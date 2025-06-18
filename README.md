# DotRun — Developer Productivity Script Manager

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

```bash
git clone https://github.com/jvPalma/dotrun
cd dotrun/
./install.sh
```

### Custom Installation Location

```bash
DOTRUN_BIN_DIR="$HOME/.local/bin" \
  bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

The installer will:

1. 📂 Copy the repo to `~/.config/dotrun`
2. 🔗 Install `drun` binary to your PATH
3. 🎨 Set up shell completion (Bash/Zsh/Fish)
4. ✅ Verify installation and show next steps

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

---

## 📁 Directory Structure

```
~/.config/dotrun/
├── bin/                      # 🎯 Executable scripts organized by category
├── helpers/                  # 📚 Shared utility libraries
├── docs/                     # 📖 Comprehensive documentation
├── drun_completion.bash      # 🎨 Bash completion script
├── drun_completion.zsh       # 🎨 Zsh completion script
└── drun_completion.fish      # 🎨 Fish completion script
```

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

### 🔄 Git Integration (Planned)

```bash
drun init --remote git@github.com:username/dotrun-config.git
# Transform your config into a Git repository for team sharing
```

### 🎨 Shell Completion (In Progress)

- **Tab Completion** - For script names and categories
- **Description Preview** - See script descriptions while typing
- **Multi-Shell Support** - Bash, Zsh, Fish compatible
- _Currently being fixed and enhanced_

### 🌍 Cross-Platform Support (Planned)

- **OS-Specific Scripts** - `tool##Linux.sh`, `tool##Darwin.sh`
- **Shell Detection** - Adapts to bash, zsh, fish automatically
- **Path Handling** - Works with different PATH configurations

---

## 📄 License

MIT License - see LICENSE file for details.

---

**Happy scripting!** 🚀

_Built with ❤️ for developers who love automation_
