# DotRun Installation Guide

## Version 1.0.1 Improvements

This version includes several installation improvements:
- **Better PATH detection**: Installer now warns if the binary directory is not in your PATH
- **Fixed shell expansion bug**: Properly uses `$HOME` instead of `~` in configuration files
- **Enhanced Windows support**: Better detection of Git Bash, MSYS2, and other Windows environments
- **Cross-platform compatibility**: Improved support for BSD variants

## File Structure & Separation

DotRun maintains a clean separation between the framework and your personal configuration. Understanding this separation is key to using DotRun effectively.

## Repository vs User Configuration

### Original Repository Structure

When you clone or download DotRun, you get this structure:

```
/path/to/dotrun/                # Original cloned repository
├── drun                        # Main executable → gets copied to ~/.local/bin/
├── install.sh                  # Installation script
├── drun_completion.bash        # Shell completions → copied to user config
├── drun_completion.zsh         # Shell completions → copied to user config
├── drun_completion.fish        # Shell completions → copied to user config
├── helpers/                    # Core libraries → copied to user config
│   ├── constants.sh            # Framework constants
│   ├── filters.sh              # File filtering utilities
│   ├── git.sh                  # Git helper functions
│   ├── lint.sh                 # ShellCheck integration
│   ├── pkg.sh                  # Package management utilities
│   └── collections.sh          # Collection management
├── examples/                   # Reference only - NOT copied
│   ├── ai/gpt/
│   ├── git/branchCleanup/
│   ├── react/rnewc/
│   └── workstation/wsc/
├── template/                   # Reference only - NOT copied
│   ├── bin/
│   ├── docs/
│   └── collection/
├── README.md                   # Documentation - NOT copied
└── docs/                       # Framework docs - NOT copied
```

### User Configuration Structure

After installation, your personal DotRun workspace lives here:

```
~/.config/dotrun/               # Your personal DotRun workspace
├── bin/                        # YOUR personal scripts (you create these)
│   ├── git/                    # Organized by category
│   ├── react/
│   ├── docker/
│   └── hello.sh                # Example (clean installs only)
├── docs/                       # YOUR script documentation (you create these)
│   └── hello.md                # Example (clean installs only)
├── helpers/                    # Framework libraries (copied from repo)
│   ├── constants.sh            # ← Copied during installation
│   ├── filters.sh              # ← Copied during installation
│   ├── git.sh                  # ← Copied during installation
│   ├── lint.sh                 # ← Copied during installation
│   ├── pkg.sh                  # ← Copied during installation
│   └── collections.sh          # ← Copied during installation
├── collections/                # Team script collections (you add these)
│   ├── devops-tools/           # Example: imported collection
│   └── frontend-utils/         # Example: imported collection
├── drun_completion.bash        # ← Copied during installation
├── drun_completion.zsh         # ← Copied during installation
└── drun_completion.fish        # ← Copied during installation
```

## Installation Process Details

### What Gets Copied Where

1. **Framework Files** (Repository → User Config):

   ```bash
   helpers/           → ~/.config/dotrun/helpers/
   drun_completion.*  → ~/.config/dotrun/
   ```

2. **Binary Installation**:

   ```bash
   drun → ~/.local/bin/drun  # (or custom DOTRUN_BIN_DIR)
   ```

3. **User Directories Created**:

   ```bash
   ~/.config/dotrun/bin/         # For your personal scripts
   ~/.config/dotrun/docs/        # For your script documentation
   ~/.config/dotrun/collections/ # For team script collections
   ```

4. **Reference Files** (Remain in Original Repository):
   - `examples/` - View for inspiration, not copied
   - `template/` - Reference for creating new scripts
   - `README.md`, `docs/` - Documentation stays in repo

### Hello Examples

On clean installations (no existing scripts), DotRun includes hello examples:

- `bin/hello.sh` - Example script
- `docs/hello.md` - Example documentation

These help you understand the structure but are skipped on existing installations.

## Framework Updates

### Updating DotRun Framework

To update the framework while preserving your personal scripts:

```bash
# Navigate to original repository
cd /path/to/original/dotrun

# Pull latest changes
git pull origin master

# Update framework files (use --force to overwrite)
./install.sh --force
```

### What Gets Updated

- ✅ Core helper libraries in `~/.config/dotrun/helpers/`
- ✅ Shell completion files
- ✅ The `drun` binary
- ❌ **Your personal scripts remain untouched**

### Safe Update Process

1. **Backup your config** (optional but recommended):

   ```bash
   cp -r ~/.config/dotrun ~/.config/dotrun.backup
   ```

2. **Update framework**:

   ```bash
   cd /path/to/original/dotrun
   git pull
   ./install.sh --force
   ```

3. **Test functionality**:
   ```bash
   drun --help
   drun -l  # List your scripts
   ```

## Dotfile Manager Integration

### Recommended Structure

For dotfile managers, we recommend this approach:

```bash
# Framework as submodule or external dependency
~/dotfiles/.local/share/dotrun-framework/  # Git submodule

# User config tracked by dotfile manager
~/dotfiles/.config/dotrun/                 # Your scripts and customizations
```

### Integration Examples

#### With yadm

```bash
# Add framework as submodule
yadm submodule add https://github.com/jvPalma/dotrun .local/share/dotrun-framework

# Install DotRun
cd ~/.local/share/dotrun-framework
./install.sh

# Add your config to yadm
yadm add ~/.config/dotrun/bin/
yadm add ~/.config/dotrun/docs/
yadm add ~/.config/dotrun/collections/
yadm commit -m "Add DotRun personal scripts"
```

#### With chezmoi

```bash
# Add to chezmoi
chezmoi add ~/.config/dotrun/bin/
chezmoi add ~/.config/dotrun/docs/
chezmoi add ~/.config/dotrun/collections/

# Framework installation in run_onchange script
# ~/.local/share/chezmoi/run_onchange_install-dotrun.sh
```

## Benefits of This Approach

### Clean Separation

- **Framework**: Updateable, version-controlled separately
- **User Config**: Your personal scripts and customizations
- **Team Collections**: Shared team scripts, isolated from personal config

### Easy Maintenance

- Update framework without affecting your scripts
- Backup only what matters (your config directory)
- No conflicts between framework updates and your work

### Flexible Integration

- Works with any dotfile manager
- Framework can be submodule, package, or manual install
- User config integrates seamlessly with existing dotfile workflows

## Troubleshooting

### File Location Quick Reference

| What                  | Where                                |
| --------------------- | ------------------------------------ |
| Your scripts          | `~/.config/dotrun/bin/`              |
| Your docs             | `~/.config/dotrun/docs/`             |
| DotRun binary         | `~/.local/bin/drun`                  |
| Framework helpers     | `~/.config/dotrun/helpers/`          |
| Shell completion      | `~/.config/dotrun/drun_completion.*` |
| Examples (reference)  | Original repo `examples/`            |
| Templates (reference) | Original repo `template/`            |

### Common Issues

**Q: Where did my script go?**
A: Check `~/.config/dotrun/bin/` - that's where your personal scripts live.

**Q: How do I see the examples?**
A: Examples stay in the original repository. View them at `/path/to/original/dotrun/examples/` or on GitHub.

**Q: Can I modify the helpers?**
A: Yes, but they'll be overwritten on framework updates. Consider creating your own helpers in `~/.config/dotrun/helpers/` with different names.

**Q: How do I know what version I have?**
A: Check the original repository: `cd /path/to/original/dotrun && git log --oneline -1`

## Next Steps

1. **Create your first script**: `drun add my-script`
2. **Explore examples**: Look in the original repository's `examples/` directory
3. **Add team collections**: `drun collection add team-scripts git@github.com:company/scripts.git`
4. **Integrate with dotfiles**: Add `~/.config/dotrun/` to your dotfile manager

This separation ensures DotRun grows with you while maintaining clean, updateable architecture.
