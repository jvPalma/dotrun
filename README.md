# DotRun — Script Management & Team Collaboration Tool

_Organize, share, and manage development scripts across teams and environments._

DotRun is a specialized script manager designed to work alongside your existing dotfile manager (yadm, chezmoi, etc.). While your dotfile manager handles configurations, DotRun focuses on executable scripts, team collaboration, and script collections. It lives in `$XDG_CONFIG_HOME/dotrun` _(defaults to `~/.config/dotrun`)_ and puts a single `drun` command on your `PATH`.

## ✨ Features

- 🚀 **Fast Script Access** - Run personal or team scripts with `drun scriptname` or `drun collection/scriptname`
- 👥 **Team Collaboration** - Share script collections across teams without exposing personal configs
- 🔗 **Dotfile Manager Integration** - Works seamlessly with yadm, chezmoi, and other dotfile managers
- 📦 **Script Collections** - Import/export script repositories for team sharing
- 📚 **Built-in Documentation** - Markdown docs alongside every script
- 🔍 **Smart Discovery** - Tree-view listing with descriptions and namespaced collections
- 🧹 **Automatic Linting** - ShellCheck integration for bash scripts
- 🎯 **Interactive Tools** - Rich CLI interfaces with colors and emojis

---

## 🚀 Installation

### Quick Install (One-liner)

Choose your preferred method:

```bash
# Using curl
curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | sh

# Using wget
wget -qO- https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | sh
```

### Custom Location Install

Set `DOTRUN_BIN_DIR` to install `drun` binary to a custom location:

```bash
# Using curl
DOTRUN_BIN_DIR="$HOME/.local/bin" curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | sh

# Using wget
DOTRUN_BIN_DIR="$HOME/.local/bin" wget -qO- https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | sh

# Using git clone
DOTRUN_BIN_DIR="$HOME/.local/bin" git clone https://github.com/jvPalma/dotrun && cd dotrun && ./install.sh
```

### Manual Install (Git Clone)

```bash
git clone https://github.com/jvPalma/dotrun
cd dotrun/
./install.sh
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
├── bin/                      # 🎯 Personal executable scripts organized by category
├── helpers/                  # 📚 Shared utility libraries
├── docs/                     # 📖 Personal script documentation
├── collections/              # 👥 Team script collections (imported repositories)
│   ├── devops-tools/         # Example: DevOps team scripts
│   └── frontend-utils/       # Example: Frontend team scripts
├── drun_completion.bash      # 🎨 Bash completion script
├── drun_completion.zsh       # 🎨 Zsh completion script
└── drun_completion.fish      # 🎨 Fish completion script
```

---

## 🛠️ Core Features

### 👥 Team Collaboration

```bash
# Import a team script collection
drun import https://github.com/company/devops-scripts.git

# Use team scripts with namespace
drun devops-scripts/deploy-staging
drun devops-scripts/backup-database

# List all available collections
drun collections list

# Export your personal scripts as a collection
drun export my-utils ./my-scripts-collection --git
```

### 🔗 Dotfile Manager Integration

```bash
# Integrate with existing yadm setup
drun yadm-init

# Your personal scripts become part of your dotfiles
# Team collections remain separate and shareable
```

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

## 🎯 Usage Examples

### Personal Script Development

```bash
# Create and manage your personal scripts
drun add git/my-branch-tool       # Create new script
drun edit git/my-branch-tool      # Edit script
drun edit:docs git/my-branch-tool # Add documentation
drun git/my-branch-tool           # Run script

# List your scripts
drun -l                           # List script names
drun -L                           # List with descriptions
```

### Team Script Collections

```bash
# Import team collections
drun import https://github.com/company/devops-tools.git
drun import https://github.com/team/frontend-utils.git

# Use team scripts
drun devops-tools/deploy-to-staging
drun frontend-utils/build-components

# List all collections and scripts
drun collections list
drun -L devops-tools/    # List scripts in specific collection
```

### Dotfile Integration Workflow

```bash
# For yadm users
drun yadm-init                    # Integrate with existing yadm repo
# Personal scripts become part of your dotfiles

# For other dotfile managers
# DotRun works independently in ~/.config/dotrun
# Your dotfile manager can include it as a submodule
```

## 🎯 Example Script Collections

DotRun includes example scripts to get you started:

#### `ai/gpt` - Generate codebase reports for AI

- 📁 **Codebase Context** - Tree structure for AI understanding
- 🎨 **File Extensions** - File type analysis for context sharing
- 💾 **Report Generation** - Saves structured reports for copy/paste

#### `git/branchCleanup` - Intelligent branch management

- ✅ **Smart Merge Detection** - Identifies merged branches automatically
- 🎨 **Visual Interface** - Color-coded status with emojis
- 🛡️ **Safety Features** - Protected branches and confirmation prompts

#### `git/branchSlice` - Precise code extraction

- 📂 **History Preservation** - Extract code with full git history
- 👥 **Co-authoring Support** - Maintain contributor attribution
- 📖 **Documentation** - Auto-generates migration docs

#### More examples available:

- **AI Tools**: [ai/gpt](./examples/ai/gpt/)
- **Git Utilities**: [branchCleanup](./examples/git/branchCleanup/), [branchSlice](./examples/git/branchSlice/)
- **React Development**: [rnewc](./examples/react/rnewc/), [rnewh](./examples/react/rnewh/)
- **Workstation Management**: [wsc](./examples/workstation/wsc/), [wss](./examples/workstation/wss/)

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

## 🚀 Integration with Dotfile Managers

DotRun is designed to work seamlessly with your existing dotfile manager:

### 🔗 yadm Integration

```bash
# Add DotRun to your yadm-managed dotfiles
yadm submodule add https://github.com/jvPalma/dotrun .config/dotrun-framework

# Set up DotRun with yadm integration
drun yadm-init

# Your personal scripts become part of your version-controlled dotfiles
# Team collections remain separate for easy sharing
```

### 🔗 chezmoi Integration

```bash
# Include DotRun in your chezmoi setup
# Add to your chezmoi.toml or install script
```

### 🔗 Git-based Dotfiles

```bash
# Add as a submodule to any git-based dotfile repository
git submodule add https://github.com/jvPalma/dotrun .config/dotrun-framework
```

### 🌟 Benefits of Integration

- **Separation of Concerns**: Personal configs (dotfiles) vs executable tools (DotRun)
- **Team Collaboration**: Share script collections without sharing personal settings
- **Version Control**: Your personal scripts become part of your dotfiles
- **Portability**: Install your dotfiles and get your scripts automatically
- **Privacy**: Team scripts are separate from personal configurations

---

## 📄 License

MIT License - see LICENSE file for details.

---

**Happy scripting!** 🚀

_Built with ❤️ for developers who love automation_
