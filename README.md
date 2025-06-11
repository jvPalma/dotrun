# DotRun — Personal Script Manager

_Write once, run anywhere._
DotRun is a Git-backed, shell-agnostic script manager that lives in `$XDG_CONFIG_HOME/dotrun` _(defaults to `~/.config/dotrun`)_ and puts a single `drun` command on your `PATH`.

---

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

### Custom binary location

Set DOTRUN_BIN_DIR inline:

```bash
DOTRUN_BIN_DIR="$HOME/.local/bin" \
  bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

The installer will:

1. Copy the repo to ~/.config/dotrun
2. Install drun binary to $DOTRUN_BIN_DIR (default /usr/local/bin, fallback ~/.local/bin)
3. Setup shell integration with ~/.drunrc
4. Install Bash completion for drun commands
5. Only copy hello examples on clean installs (use --force to override)

---

## Directory Layout

```bash
~/.config/dotrun/
├── bin/          # your runnable scripts
├── helpers/      # shared libraries (filters.sh, git.sh, pkg.sh, …)
├── docs/         # Markdown docs auto-shown by `drun help`
├── drun_completion
└── README.md
```

**Repository also includes:**

```bash
examples/         # Script examples you can copy and customize
├── backup.md     # Backup and sync scripts
├── git.md        # Git workflow automation
├── docker.md     # Container management scripts
└── ...           # More categories coming soon
```

---

## Everyday Commands

| Command                | What it does                                           |
| ---------------------- | ------------------------------------------------------ |
| `drun -l`              | List scripts (names) in tree form                      |
| `drun -L docs/`        | List scripts with docs scoped to a folder              |
| `drun add tools/build` | Scaffold (if absent), open in $EDITOR, then ShellCheck |
| `drun edit foo`        | Open & lint an existing script                         |
| `drun help foo`        | Show the ### DOC section of foo.sh                     |
| `drun docs <name>`     | Show documentation for a script                        |
| `drun edit:docs`       | Edit documentation files                               |

_(ShellCheck runs automatically after add/edit if present; install with `sudo apt install shellcheck` or see per-distro hints.)_

---

## Script Examples

The repository includes a collection of ready-to-use script examples in the `examples/` folder. Each `.md` file contains tested scripts organized by category that you can copy and customize for your needs.

### Available Categories

- **backup.md** - Backup and synchronization scripts

  - Daily document backup automation
  - Database backup scripts
  - Cloud storage sync workflows
  - System configuration backup

- **git.md** - Git workflow automation

  - Branch cleanup and maintenance
  - Automated commit and push workflows
  - Repository health checks
  - Multi-repo operations

- **docker.md** - Container management scripts

  - Container cleanup and maintenance
  - Development environment setup
  - Image optimization scripts
  - Docker Compose workflows

- **system.md** - System administration scripts
  - Log rotation and cleanup
  - Service monitoring
  - Resource usage reports
  - Automated updates

### How to Use Examples

1. Browse the `examples/` folder in the repository
2. Find scripts that match your workflow
3. Copy the script content to your local DotRun instance:
   ```bash
   drun add my-category/script-name
   # Paste the example script content
   ```
4. Customize variables and paths for your environment
5. Test and enjoy your new automation!

---

## Example: Creating Your First Script

Here's how to create a script from start to finish and manage it with a dotfiles manager:

### 1. Create a new script

```bash
# Create and edit a new backup script
drun add backup/daily-backup

# This opens your $EDITOR with a template, add your script content:
#!/usr/bin/env bash
### DOC: Daily backup script for important files
set -euo pipefail

cp -r ~/Documents/ ~/Backups/Documents/
echo "Daily backup completed at $(date)"
```

### 2. Add documentation

```bash
# Create documentation for your script
drun edit:docs backup/daily-backup.md

# Add markdown documentation:
# Daily Backup Script
#
# Backs up Documents folder to ~/Backups/Documents/
# Uses standard cp command for simple file copying
```

### 3. Test and run

```bash
# Test your script
drun backup/daily-backup

# View help
drun help backup/daily-backup

# List all scripts
drun -l
```

### 4. Manage with dotfiles (recommended)

DotRun works excellently with dotfiles managers. We recommend **yadm** for its simplicity and Git integration:

```bash
# Install yadm
sudo apt install yadm  # or brew install yadm

# Initialize your dotfiles repo
yadm init
yadm remote add origin https://github.com/yourusername/dotfiles.git

# Add DotRun config to your dotfiles
yadm add ~/.config/dotrun/
yadm add ~/.drunrc

# Commit and push
yadm commit -m "Add DotRun configuration and scripts"
yadm push -u origin main

# On a new machine, simply:
yadm clone https://github.com/yourusername/dotfiles.git
# Your scripts and configs are automatically available!
```

This approach lets you sync your personal scripts across all your machines seamlessly.

---

## Shell Integration

DotRun supports bash, zsh, and fish shells with intelligent detection. After installation:

- **Bash/Zsh**: Add `source ~/.drunrc` to your shell config
- **Fish**: Add `source ~/.drunrc` to `~/.config/fish/config.fish`

The installer provides specific instructions for your detected shell.

---

## Contributing

1. Fork and clone this repository
2. Run `./install.sh` (installs to your config dir for development)
3. Create or edit scripts in `bin/`, docs in `docs/`, helpers in `helpers/`
4. Test with `drun <your-script>`

Happy scripting! 🚀
