# Migration Guide: DotRun 2.x → 3.0.0

## Overview

DotRun 3.0.0 introduces a **unified file-based workflow** for aliases and configs, aligning them with the existing scripts pattern. This is a breaking change that significantly improves organization and reduces clutter.

**What Changed:**
- ✅ Scripts workflow: No changes (fully backward compatible)
- ✅ Collections workflow: No changes (fully backward compatible)
- ⚠️ **Aliases workflow**: Changed from command-line values to file-based editing
- ⚠️ **Config workflow**: Changed from command-line values to file-based editing

**Migration Time:** ~15-30 minutes for most users

---

## Breaking Changes

### 1. Aliases Workflow

#### Before (2.x)
```bash
# Single alias per command
dr aliases add gs 'git status'
dr aliases add gc 'git commit'
dr aliases add gp 'git push'

# Result: Each command creates one alias
```

#### After (3.0.0)
```bash
# Multiple aliases in one file
dr aliases set 01-git  # Opens editor

# In the editor, add all git aliases:
alias gs='git status'
alias gc='git commit'
alias gp='git push'

# Result: One file (01-git.aliases) contains all git aliases
```

**Why This Is Better:**
- ✅ Organize related aliases together (all git, all docker, etc.)
- ✅ Numbered files control load order (01 loads before 02)
- ✅ Edit multiple aliases at once
- ✅ Matches established convention (matches scripts pattern)

### 2. Config Workflow

#### Before (2.x)
```bash
# Single config per command
dr config set API_KEY "abc123"
dr config set DB_HOST "localhost"
dr config set NODE_ENV "development"

# With secure flag
dr config set SECRET "sensitive" --secure
```

#### After (3.0.0)
```bash
# Multiple exports in one file
dr config set api/keys  # Opens editor

# In the editor, add all related configs:
export API_KEY="abc123"
export DB_HOST="localhost"
export NODE_ENV="development"

# Secure values (planned for 3.1.0):
# SECURE
export SECRET="sensitive"
```

**Why This Is Better:**
- ✅ Organize related configs together (all API keys, all database settings)
- ✅ Category folders for better organization (api/keys, database/prod)
- ✅ Standard bash syntax (can copy-paste between files)
- ✅ Version control friendly

---

## Migration Steps

### Step 1: Identify Your Current Aliases (If Any)

**If you have 2.x aliases**, list them first:

```bash
# In 2.x (if this command exists)
dr aliases list

# Or manually check
ls ~/.config/dotrun/aliases/
```

**Export your aliases** before upgrading:
```bash
# Save current aliases to a file
alias > ~/dotrun-2x-aliases-backup.txt
```

### Step 2: Upgrade to 3.0.0

```bash
# Pull latest version
cd /path/to/dotrun
git pull origin main
git checkout v3.0.0

# Or reinstall
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/v3.0.0/install.sh)

# Restart your shell
exec $SHELL
```

### Step 3: Recreate Aliases Using New Workflow

**Organize aliases by category** using numbered files:

```bash
# Git aliases (loads first)
dr aliases set 01-git
# Add: alias gs='git status', alias gc='git commit', etc.

# Docker aliases (loads second)
dr aliases set 02-docker
# Add: alias dk='docker', alias dkc='docker-compose', etc.

# Custom shortcuts (loads later)
dr aliases set 10-custom
# Add your custom aliases
```

**Reload aliases** in current shell:
```bash
dr aliases reload
```

### Step 4: Recreate Configs Using New Workflow

**Organize configs by category** using numbered files:

```bash
# PATH and environment basics (loads first)
dr config set 01-paths
# Add: export PATH="$HOME/bin:$PATH", etc.

# API keys and secrets (category folder)
dr config set api/keys
# Add: export API_KEY="...", export API_SECRET="...", etc.

# Database configuration
dr config set database/prod
# Add: export DB_HOST="...", export DB_PORT="...", etc.
```

**Restart shell** to load new configs:
```bash
exec $SHELL
```

### Step 5: Verify Everything Works

```bash
# Check aliases loaded
alias gs  # Should show: gs='git status'

# Check configs loaded
echo $API_KEY  # Should show your API key

# List all alias files
dr aliases list

# List all config files
dr config list

# List scripts (should be unchanged)
dr -l
```

---

## Migration Examples

### Example 1: Simple Git Aliases

**Before (2.x):**
```bash
dr aliases add gs 'git status'
dr aliases add gc 'git commit'
dr aliases add gp 'git push'
dr aliases add gl 'git log --oneline'
```

**After (3.0.0):**
```bash
# Create one file with all git aliases
dr aliases set 01-git

# Editor opens ~/.config/dotrun/aliases/01-git.aliases
# Add:
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
```

**Result:** 4 separate commands → 1 organized file

### Example 2: API Configuration

**Before (2.x):**
```bash
dr config set GITHUB_TOKEN "ghp_xxx"
dr config set OPENAI_API_KEY "sk-xxx"
dr config set AWS_ACCESS_KEY "AKIA..."
dr config set AWS_SECRET_KEY "..." --secure
```

**After (3.0.0):**
```bash
# Organize by service
dr config set api/github
# Add: export GITHUB_TOKEN="ghp_xxx"

dr config set api/openai
# Add: export OPENAI_API_KEY="sk-xxx"

dr config set api/aws
# Add:
# export AWS_ACCESS_KEY="AKIA..."
# # SECURE (planned for 3.1.0)
# export AWS_SECRET_KEY="..."
```

**Result:** Better organization by service, easier to manage

### Example 3: Complex Workflow

**Before (2.x):**
```bash
# 20 different aliases added one by one
dr aliases add gs 'git status'
dr aliases add gc 'git commit'
# ... 18 more commands

# 15 different configs added one by one
dr config set API_KEY_1 "..."
dr config set API_KEY_2 "..."
# ... 13 more commands
```

**After (3.0.0):**
```bash
# Organize into logical groups

# Git aliases (5 aliases in one file)
dr aliases set 01-git

# Docker aliases (6 aliases in one file)
dr aliases set 02-docker

# Navigation aliases (4 aliases in one file)
dr aliases set 03-nav

# Custom shortcuts (5 aliases in one file)
dr aliases set 10-custom

# API configs by service
dr config set api/github
dr config set api/aws
dr config set api/openai

# Database configs by environment
dr config set database/dev
dr config set database/prod
```

**Result:** 35 commands → ~9 organized files

---

## File Naming Conventions

### Numbered Prefix Pattern

Use a **two-digit number prefix** to control load order:

```
01-first-to-load.aliases
02-second-to-load.aliases
10-later-items.aliases
```

**Why numbered?**
- Controls execution order (PATH setup before tools that need it)
- Visual organization in directory listings
- Matches established DotRun patterns

### Category Folders

Use **folders** to organize by topic or service:

```
~/.config/dotrun/aliases/
├── 01-git.aliases
├── 02-docker.aliases
└── navigation/
    ├── 01-cd.aliases
    └── 02-jump.aliases

~/.config/dotrun/configs/
├── 01-paths.config
├── api/
│   ├── github.config
│   ├── openai.config
│   └── aws.config
└── database/
    ├── dev.config
    └── prod.config
```

**Best Practices:**
- Use numbers for load order (01, 02, 03)
- Use folders for categorization (api/, database/, etc.)
- Keep related items together (all git aliases in one file)
- Start with 01, 02, etc. to leave room for future additions

---

## Common Migration Patterns

### Pattern 1: Load Order Dependencies

**Problem:** Database tools need database configs loaded first

**Solution:**
```bash
# Load database config early
dr config set 01-database
# export DB_HOST="localhost"
# export DB_PORT="5432"

# Load tools that use DB later
dr config set 05-db-tools
# export PGUSER="admin"
# export PGPASSWORD="..."
```

### Pattern 2: Security Sensitive Values

**Problem:** API keys and secrets need special handling

**Current (3.0.0):**
```bash
dr config set api/secrets
# export API_KEY="sensitive-value"
# Note: Masking planned for 3.1.0
```

**Future (3.1.0):**
```bash
dr config set api/secrets
# # SECURE
# export API_KEY="sensitive-value"
# Values will be masked in `dr config list` output
```

### Pattern 3: Conditional Aliases

**Problem:** Different aliases for different environments

**Solution:**
```bash
# Development aliases
dr aliases set dev/shortcuts
# alias start='npm run dev'
# alias test='npm test'

# Production aliases
dr aliases set prod/shortcuts
# alias deploy='./deploy.sh prod'
# alias logs='tail -f /var/log/app.log'

# Load the appropriate one based on environment
```

---

## Troubleshooting

### Issue: "EDITOR environment variable is not set"

**Solution:**
```bash
# Set EDITOR in your shell config (~/.bashrc, ~/.zshrc, etc.)
export EDITOR="nano"  # or code, vim, etc.

# Reload shell
exec $SHELL

# Try again
dr aliases set 01-git
```

### Issue: "Aliases not loading in new shells"

**Check:** Is ~/.drrc sourced in your shell config?

```bash
# In ~/.bashrc or ~/.zshrc, should have:
[[ -f ~/.drrc ]] && source ~/.drrc

# Reload
exec $SHELL
```

### Issue: "Old aliases still showing up"

**Solution:** Remove old alias files manually:

```bash
# List current alias files
ls ~/.config/dotrun/aliases/

# Remove old format files (if any exist)
rm ~/.config/dotrun/aliases/old-file.sh

# Reload
dr aliases reload
```

### Issue: "Config values not available"

**Check load order:**
```bash
# List configs
dr config list

# Ensure configs are numbered correctly
# 01-paths should load before tools that need PATH
```

---

## Rollback Plan

If you need to rollback to 2.x:

```bash
# 1. Backup your 3.0 files
cp -r ~/.config/dotrun/aliases ~/dotrun-3.0-aliases-backup
cp -r ~/.config/dotrun/configs ~/dotrun-3.0-configs-backup

# 2. Checkout 2.x
cd /path/to/dotrun
git checkout v2.0.0
./install.sh --force

# 3. Restore old aliases/configs (if you backed them up)
# Manually restore using old dr aliases add commands

# 4. Restart shell
exec $SHELL
```

**Note:** You'll need to recreate aliases/configs using old command format.

---

## New Features in 3.0.0

### 1. Idempotent Set Commands

`dr aliases set` and `dr config set` work for both create and edit:

```bash
# First time: creates file with skeleton
dr aliases set 01-git

# Second time: opens existing file for editing
dr aliases set 01-git
```

### 2. Category Filtering

List aliases or configs by category:

```bash
# List all alias files
dr aliases list

# List only files in specific category
dr aliases list --category git

# Same for configs
dr config list --category api
```

### 3. Empty Directory Cleanup

Removing files automatically cleans up empty parent directories:

```bash
# Remove config file
dr config remove api/keys

# If api/ folder is now empty, it's automatically removed
```

### 4. Comprehensive Skeletons

All new files include helpful documentation and examples:

```bash
# Create new alias file
dr aliases set test

# Opens editor with:
#!/usr/bin/env bash
# DotRun Aliases File
# Examples:
#   alias ll='ls -lah'
#   alias gs='git status'
```

---

## FAQ

**Q: Can I still use the old command format?**
A: No, the old command-line syntax (`dr aliases add name 'value'`) has been removed in 3.0.0.

**Q: What happens to my existing 2.x aliases and configs?**
A: They won't automatically migrate. You need to manually recreate them using the new file-based workflow.

**Q: Why the change to file-based?**
A: Better organization, matches scripts pattern, easier to version control, and reduces file clutter.

**Q: Can I organize aliases in folders?**
A: Yes! Use `dr aliases set git/shortcuts` to create `~/.config/dotrun/aliases/git/shortcuts.aliases`

**Q: How do I know what number to use?**
A: Start with 01, 02, 03. Use lower numbers for dependencies (paths, core configs) and higher numbers for applications.

**Q: What about the # SECURE marker?**
A: Planned for v3.1.0. For now, just document sensitive values with comments.

**Q: Do scripts work the same way?**
A: Yes! Scripts are completely unchanged and fully backward compatible.

**Q: Do collections work the same way?**
A: Yes! Collections are completely unchanged and fully backward compatible.

**Q: How do I reload aliases without restarting my shell?**
A: Use `dr aliases reload`

**Q: Is there a reload command for configs?**
A: Not in 3.0.0 (planned for 3.1.0). For now, restart your shell: `exec $SHELL`

---

## Summary Checklist

- [ ] Backup existing aliases: `alias > ~/aliases-backup.txt`
- [ ] Upgrade to 3.0.0: `git pull && git checkout v3.0.0`
- [ ] Set EDITOR if needed: `export EDITOR="nano"`
- [ ] Recreate aliases using `dr aliases set NN-category`
- [ ] Recreate configs using `dr config set NN-category` or `category/name`
- [ ] Reload: `dr aliases reload` and `exec $SHELL`
- [ ] Verify: `dr aliases list` and `dr config list`
- [ ] Test: Run a few aliases and check config variables

**Total Time:** 15-30 minutes

---

## Getting Help

If you encounter issues:

1. Check this migration guide first
2. Read updated README: https://github.com/jvPalma/dotrun/blob/v3.0.0/README.md
3. Open an issue: https://github.com/jvPalma/dotrun/issues
4. Check examples: https://github.com/jvPalma/dotrun/tree/v3.0.0/examples

**We're here to help!** The new workflow is significantly better once you get used to it.

---

**Welcome to DotRun 3.0.0!** 🚀
