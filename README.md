# DotRun — Personal & Team Script Manager

*Write once, run anywhere.*
DotRun is a Git-backed, shell-agnostic script manager that lives in `$XDG_CONFIG_HOME/dotrun` *(defaults to `~/.config/dotrun`)* and puts a single `drun` command on your `PATH`.

---

## Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

Custom binary location

Set DOTRUN_BIN_DIR inline:

```bash
DOTRUN_BIN_DIR="$HOME/.local/bin" \
  bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

The installer will:

1. Copy the repo to ~/.config/dotrun

2. Copy (or symlink) drun into $DOTRUN_BIN_DIR (default /usr/local/bin)

3. Install Bash completion (adds source command to Zsh/Fish if those dirs exist)

4. Tell you how to source completion immediately


---

Directory Layout

```bash
~/.config/dotrun
├── bin/          # your runnable scripts
├── helpers/      # shared libraries (filters.sh, git.sh, pkg.sh, …)
├── docs/         # Markdown docs auto-shown by `drun help`
├── drun_completion
└── repo.git/     # (bare git repo — created automatically on `drun init`)
```

---

Everyday Commands

Command	What it does

```bash
drun -l                 List scripts (names) in tree form
drun -L docs/           List scripts with docs scoped to a folder
drun add tools/build    Scaffold (if absent), open in $EDITOR, then ShellCheck
drun edit foo           Open & lint an existing script
drun help foo           Show the ### DOC section of foo.sh


(ShellCheck runs automatically after add/edit if present; install with
sudo apt install shellcheck or see per-distro hint.)

```

---

Advanced / Team Features

Git Sync – drun init --remote <url> turns the config dir into a bare repo; push–pull scripts just like dotfiles managers.

Script Templates – drun new --lang bash|python|zsh foo generates a best-practice header, usage, and argument parsing.

OS-specific Files – mytool##Darwin.sh, mytool##Linux.sh — DotRun automatically links the right one on each machine.

Reusable Filters – helpers/filters.sh centralises ignore patterns so every script shares the same blacklist (e.g., .git, node_modules, etc.).

Package Hints – helpers/pkg.sh prints apt, dnf, brew, pkg (Termux) install lines when a required binary is missing.


See docs/ for detailed per-script guides.


---

Contributing

1. Fork and clone.

2. ./install.sh (installs to your config dir; uses symlink so changes are live).

3. Create or edit scripts in bin/, docs in docs/, helpers in helpers/.


Happy scripting! 🚀

