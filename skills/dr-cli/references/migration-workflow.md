# Migration Workflow Reference

This is the MANDATORY reference for interactive file migration into DotRun.

## Overview

This workflow handles user requests like:

- "help me migrate ~/.bash_profile into dotrun"
- "migrate my ~/.zshrc to dr"
- "import my shell config into dotrun"

## Phase 0: Identification

**Extract the file path from user request and expand it:**

```bash
# User says: "migrate ~/.bash_profile"
FILE_TO_MIGRATE="~/.bash_profile"

# Expand ~ to $HOME
FILE_TO_MIGRATE="${HOME}/.bash_profile"
```

**Common files to migrate:**

- `~/.bash_profile`, `~/.bashrc`
- `~/.zshrc`, `~/.zsh_profile`
- `~/.profile`
- Custom shell configs

## Phase 1: Verification

**Check that the file exists and show basic info:**

```bash
# Verify file exists
if [ ! -f "$FILE_TO_MIGRATE" ]; then
    echo "Error: File not found: $FILE_TO_MIGRATE"
    exit 1
fi

# Show file info
ls -lh "$FILE_TO_MIGRATE"
wc -l "$FILE_TO_MIGRATE"
```

**Present to user:**

```
Found: /home/user/.bash_profile
Size: 4.2K
Lines: 127
```

## Phase 2: Backup

**Create a backup before any migration:**

```bash
# Create backup with timestamp
BACKUP_FILE="${FILE_TO_MIGRATE}.bk.$(date +%Y%m%d-%H%M%S)"
cp "$FILE_TO_MIGRATE" "$BACKUP_FILE"

# Confirm backup created
ls -lh "$BACKUP_FILE"
```

**Present to user:**

```
✓ Backup created: /home/user/.bash_profile.bk.20260204-143022
```

## Phase 3: Analysis

### 3.1 Extract ALIASES

**Pattern matching for aliases:**

```regex
^alias\s+(\w+)=['"](.+)['"]
^alias\s+(\w+)=(.+)
```

**Categorize by prefix:**

- `git*` → git operations (gs, gp, gl, etc.)
- `docker*`, `dk*` → docker operations
- `k*`, `kubectl*` → kubernetes
- `tf*`, `terraform*` → terraform
- `ll`, `la`, `l` → file listing
- `..`, `...` → directory navigation
- Generic/misc → everything else

**Example extraction:**

```
Aliases found: 23

Git (8):
  gs='git status'
  gp='git pull'
  gco='git checkout'

Docker (5):
  dps='docker ps'
  dimg='docker images'

File ops (4):
  ll='ls -lah'
  la='ls -A'

Navigation (3):
  ..='cd ..'
  ...='cd ../..'

Misc (3):
  reload='source ~/.bash_profile'
  myip='curl ifconfig.me'
```

### 3.2 Extract CONFIGS

**Pattern matching for configs:**

```regex
^export\s+(\w+)=(.+)
^eval\s+"?\$\((.+)\)"?
^source\s+(.+)
^\[\s+-s\s+(.+)\s+\]\s+&&\s+source\s+(.+)
^\.\s+(.+)
```

**Categorize configs:**

1. **PATH modifications** (critical - must load first)
   - `export PATH=`
   - Pattern: `PATH=.*:.*PATH`

2. **Tool initialization** (load after PATH)
   - `eval "$(rbenv init -)"`
   - `eval "$(pyenv init -)"`
   - `[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"`

3. **API keys and secrets**
   - `export AWS_ACCESS_KEY_ID=`
   - `export GITHUB_TOKEN=`

4. **Environment variables**
   - `export EDITOR=`
   - `export LANG=`

5. **Source statements**
   - `source ~/.custom_profile`
   - `. /usr/local/etc/bash_completion`

**Example extraction:**

```
Configs found: 15

PATH (3):
  export PATH="$HOME/bin:$PATH"
  export PATH="/usr/local/opt/ruby/bin:$PATH"

Tool init (4):
  eval "$(rbenv init - bash)"
  eval "$(pyenv init -)"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

Env vars (5):
  export EDITOR=vim
  export VISUAL=vim
  export LANG=en_US.UTF-8

API keys (2):
  export GITHUB_TOKEN=ghp_xxxxx
  export AWS_PROFILE=default

Source (1):
  source ~/.custom_functions
```

### 3.3 Extract SCRIPTS (functions)

**Pattern matching for functions:**

```regex
^function\s+(\w+)\s*\(\)\s*\{
^(\w+)\s*\(\)\s*\{
```

**Classify functions:**

1. **Simple (convert to alias):**
   - Single command
   - No arguments
   - No logic
   - Example: `function reload() { source ~/.bash_profile; }`

2. **Complex (keep as script):**
   - Multiple commands
   - Uses arguments ($1, $2, $@)
   - Conditional logic (if/then/case)
   - Loops (for/while)
   - Example: Git utilities, docker wrappers

**Example extraction:**

```
Functions found: 8

Simple → Convert to alias (3):
  reload() { source ~/.bash_profile; }
  → alias reload='source ~/.bash_profile'

  weather() { curl wttr.in; }
  → alias weather='curl wttr.in'

Complex → Keep as script (5):
  git-cleanup() {
    # 15 lines, uses $1, has if/then
  }
  → scripts/git-cleanup.sh

  docker-cleanup() {
    # 20 lines, uses $@, loops
  }
  → scripts/docker-cleanup.sh
```

## Phase 4: Migration Plan

**Present a complete migration plan to the user:**

### Load Order Strategy

1. **01-paths.config** - PATH modifications (must be first)
2. **02-env.config** - Environment variables
3. **03-api-keys.config** - Secrets and tokens
4. **04-tools.config** - Tool initialization (rbenv, pyenv, nvm)
5. **05-sources.config** - External source statements
6. **05-git.aliases** - Git aliases
7. **06-docker.aliases** - Docker aliases
8. **07-k8s.aliases** - Kubernetes aliases
9. **08-file-ops.aliases** - File operation aliases
10. **09-nav.aliases** - Navigation aliases
11. **10-misc.aliases** - Miscellaneous aliases
12. **scripts/\*** - Individual script files

### Migration Table

```
╔═══════════════════════════════════════════════════════════════════════╗
║ Source                    │ Type     │ Target                         ║
╠═══════════════════════════════════════════════════════════════════════╣
║ export PATH="$HOME/bin"   │ CONFIG   │ configs/01-paths.config        ║
║ export EDITOR=vim         │ CONFIG   │ configs/02-env.config          ║
║ export GITHUB_TOKEN=...   │ CONFIG   │ configs/03-api-keys.config     ║
║ eval "$(rbenv init -)"    │ CONFIG   │ configs/04-tools.config        ║
║ source ~/.custom          │ CONFIG   │ configs/05-sources.config      ║
║ alias gs='git status'     │ ALIAS    │ aliases/05-git.aliases         ║
║ alias gp='git pull'       │ ALIAS    │ aliases/05-git.aliases         ║
║ alias dps='docker ps'     │ ALIAS    │ aliases/06-docker.aliases      ║
║ alias ll='ls -lah'        │ ALIAS    │ aliases/08-file-ops.aliases    ║
║ alias ..='cd ..'          │ ALIAS    │ aliases/09-nav.aliases         ║
║ function reload()         │ ALIAS    │ aliases/10-misc.aliases        ║
║ function git-cleanup()    │ SCRIPT   │ scripts/git-cleanup.sh         ║
║ function docker-cleanup() │ SCRIPT   │ scripts/docker-cleanup.sh      ║
╚═══════════════════════════════════════════════════════════════════════╝

Total items: 45
  - Aliases: 23
  - Configs: 15
  - Scripts: 7 (5 complex, 2 converted to aliases)
```

### Load Order Reasoning

**Why this order matters:**

1. **PATH first** - Other tools/scripts need correct PATH to work
2. **Env vars next** - Tools may read env vars during init
3. **API keys** - Isolated for security, easy to exclude from git
4. **Tool init** - Requires PATH to be set first
5. **Sources** - May depend on above configs
6. **Aliases** - Order by category for organization
7. **Scripts** - Loaded last, can use aliases/configs

## Phase 5: User Approval

**Present the plan and wait for explicit approval:**

```
========================================
MIGRATION PLAN SUMMARY
========================================

Source file: /home/user/.bash_profile
Backup: /home/user/.bash_profile.bk.20260204-143022

Will create:
  5 config files (15 settings)
  6 alias files (23 aliases)
  5 script files

Estimated time: 2-3 minutes

⚠️  IMPORTANT:
  - Original file will NOT be deleted until you confirm
  - Backup is safely stored
  - You can test before cleanup

Do you want to proceed with this migration plan?
Type 'yes' to continue, or ask questions/request changes.
```

**Wait for:**

- Explicit "yes", "proceed", "go ahead", "confirm"
- NOT: vague acknowledgment like "ok", "sure"

**If user asks questions or requests changes:**

- Answer questions
- Modify plan as needed
- Re-present modified plan
- Ask for approval again

## Phase 6: Execute Migration

**Execute the migration plan step by step:**

### 6.1 Create Config Files

```bash
# 01-paths.config
dr -c set 01-paths <<'EOF'
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
EOF

# 02-env.config
dr -c set 02-env <<'EOF'
export EDITOR=vim
export VISUAL=vim
export LANG=en_US.UTF-8
EOF

# 03-api-keys.config
dr -c set 03-api-keys <<'EOF'
export GITHUB_TOKEN=ghp_xxxxx
export AWS_PROFILE=default
EOF

# 04-tools.config
dr -c set 04-tools <<'EOF'
eval "$(rbenv init - bash)"
eval "$(pyenv init -)"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
EOF

# 05-sources.config
dr -c set 05-sources <<'EOF'
source ~/.custom_functions
EOF
```

### 6.2 Create Alias Files

```bash
# 05-git.aliases
dr -a set 05-git <<'EOF'
alias gs='git status'
alias gp='git pull'
alias gco='git checkout'
alias gcm='git commit -m'
alias gaa='git add --all'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias gb='git branch'
EOF

# 06-docker.aliases
dr -a set 06-docker <<'EOF'
alias dps='docker ps'
alias dimg='docker images'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
EOF

# 08-file-ops.aliases
dr -a set 08-file-ops <<'EOF'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias tree='tree -C'
EOF

# 09-nav.aliases
dr -a set 09-nav <<'EOF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
EOF

# 10-misc.aliases
dr -a set 10-misc <<'EOF'
alias reload='source ~/.drrc'
alias weather='curl wttr.in'
alias myip='curl ifconfig.me'
EOF
```

### 6.3 Create Script Files

```bash
# scripts/git-cleanup.sh
dr set scripts/git-cleanup <<'EOF'
#!/usr/bin/env bash
# Clean up merged git branches

# ... (full function body)
EOF

# scripts/docker-cleanup.sh
dr set scripts/docker-cleanup <<'EOF'
#!/usr/bin/env bash
# Clean up docker containers and images

# ... (full function body)
EOF
```

### Progress Reporting

**Show progress as files are created:**

```
Creating configs...
  ✓ configs/01-paths.config (3 settings)
  ✓ configs/02-env.config (5 settings)
  ✓ configs/03-api-keys.config (2 settings)
  ✓ configs/04-tools.config (4 settings)
  ✓ configs/05-sources.config (1 setting)

Creating aliases...
  ✓ aliases/05-git.aliases (8 aliases)
  ✓ aliases/06-docker.aliases (5 aliases)
  ✓ aliases/08-file-ops.aliases (4 aliases)
  ✓ aliases/09-nav.aliases (3 aliases)
  ✓ aliases/10-misc.aliases (3 aliases)

Creating scripts...
  ✓ scripts/git-cleanup.sh
  ✓ scripts/docker-cleanup.sh
  ✓ scripts/docker-logs.sh
  ✓ scripts/find-large-files.sh
  ✓ scripts/port-kill.sh

Migration complete! ✓
```

## Phase 7: Verification

**Present a verification checklist to the user:**

```
========================================
VERIFICATION CHECKLIST
========================================

Please verify the migration was successful:

[ ] 1. List new aliases:
    $ dr -a -L

    Expected: Should show 05-git, 06-docker, 08-file-ops, 09-nav, 10-misc

[ ] 2. List new configs:
    $ dr -c -L

    Expected: Should show 01-paths, 02-env, 03-api-keys, 04-tools, 05-sources

[ ] 3. List new scripts:
    $ dr -L | grep scripts/

    Expected: Should show all 5 scripts

[ ] 4. Reload shell configuration:
    $ source ~/.drrc

    Expected: No errors

[ ] 5. Test a few key aliases:
    $ type gs
    $ type dps
    $ type ll

    Expected: Each should show "is aliased to..."

[ ] 6. Test a config is loaded:
    $ echo $EDITOR

    Expected: Should show "vim"

[ ] 7. Test a script is available:
    $ type git-cleanup

    Expected: Should show script location

[ ] 8. Check original file is untouched:
    $ ls -l ~/.bash_profile

    Expected: File still exists, same size

[ ] 9. Verify backup exists:
    $ ls -l ~/.bash_profile.bk.*

    Expected: Backup file present

========================================

Run each command and verify the output matches expectations.
Let me know when all checks pass, or if any issues arise.

⚠️  DO NOT proceed to cleanup until ALL checks pass!
```

**Interactive verification:**

- User runs each command
- User reports results
- Address any issues before cleanup
- Only proceed when user explicitly confirms ALL checks pass

## Phase 8: Cleanup

**ONLY after user confirms 100% success:**

```
========================================
CLEANUP PHASE
========================================

All verification checks passed! ✓

Now we can safely clean up the original file.

⚠️  FINAL WARNING:
  - Original file will be DELETED: ~/.bash_profile
  - Backup will be KEPT: ~/.bash_profile.bk.20260204-143022
  - You can restore from backup anytime if needed

Options:
  1. Delete original file (recommended - fully migrated)
  2. Keep original file (if you want both systems)
  3. Keep both for X days (transition period)

What would you like to do?
```

**Wait for user decision:**

### Option 1: Delete original

```bash
rm ~/.bash_profile
echo "✓ Original file deleted"
echo "✓ Backup preserved: ~/.bash_profile.bk.20260204-143022"
echo ""
echo "You can restore anytime with:"
echo "  cp ~/.bash_profile.bk.20260204-143022 ~/.bash_profile"
```

### Option 2: Keep original

```bash
echo "✓ Original file preserved: ~/.bash_profile"
echo "✓ Backup preserved: ~/.bash_profile.bk.20260204-143022"
echo ""
echo "Note: You now have two shell config systems:"
echo "  - DotRun (~/.drrc) - new system"
echo "  - Original (~/.bash_profile) - old system"
echo ""
echo "Make sure to only source one in your shell startup."
```

### Option 3: Transition period

```bash
# Rename original with date
mv ~/.bash_profile ~/.bash_profile.old.$(date +%Y%m%d)

echo "✓ Original file renamed: ~/.bash_profile.old.20260204"
echo "✓ Backup preserved: ~/.bash_profile.bk.20260204-143022"
echo ""
echo "Set a reminder to delete ~/.bash_profile.old.* in 30 days if no issues."
```

## Post-Migration

**Show final summary and next steps:**

```
========================================
MIGRATION COMPLETE! 🎉
========================================

Summary:
  ✓ Migrated 45 items from ~/.bash_profile
  ✓ Created 5 config files
  ✓ Created 6 alias files
  ✓ Created 5 scripts
  ✓ Backup preserved
  ✓ All verification checks passed

Your shell is now managed by DotRun!

Quick reference:
  - View all: dr -L
  - View aliases: dr -a -L
  - View configs: dr -c -L
  - Edit alias: dr -a edit 05-git
  - Edit config: dr -c edit 01-paths
  - Add new alias: dr -a set my-aliases
  - Reload: source ~/.drrc

Documentation:
  - Overview: cat ~/.dotrun/README.md
  - Examples: cat ~/.dotrun/docs/EXAMPLES.md
  - Categories: cat ~/.dotrun/docs/CATEGORIES.md

========================================
```

## Edge Cases and Troubleshooting

### File not found

```
User: "migrate ~/.bash_profile"
Agent: "File not found: /home/user/.bash_profile"
       "Did you mean: ~/.bashrc, ~/.profile, ~/.zshrc?"
```

### Empty file

```
Agent: "File is empty (0 lines)"
       "Nothing to migrate. Aborting."
```

### Already migrated

```
Agent: "Detected existing DotRun migration markers in file"
       "This file may have already been migrated."
       "Options:"
       "  1. Show current DotRun entries"
       "  2. Re-migrate anyway (will create duplicates)"
       "  3. Abort"
```

### Source statements to non-existent files

```
Agent: "Warning: Source file not found"
       "  source ~/.custom_functions"
       "  File: /home/user/.custom_functions (does not exist)"
       ""
       "Options:"
       "  1. Skip this source statement"
       "  2. Create empty placeholder file"
       "  3. Abort migration"
```

### Complex patterns not recognized

```
Agent: "Found 3 lines that don't match known patterns:"
       ""
       "  47: [ -f ~/.fzf.bash ] && source ~/.fzf.bash"
       "  89: PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"
       "  102: shopt -s histappend"
       ""
       "How should these be handled?"
       "  1. Add to misc config file"
       "  2. Skip (document in migration log)"
       "  3. Review each manually"
```

### API keys in plain text

```
Agent: "⚠️  SECURITY WARNING"
       ""
       "Found API keys/secrets in plain text:"
       "  - GITHUB_TOKEN"
       "  - AWS_ACCESS_KEY_ID"
       "  - OPENAI_API_KEY"
       ""
       "Recommendations:"
       "  1. Store in password manager (1Password, pass, etc.)"
       "  2. Use secret management tool (Vault, AWS Secrets Manager)"
       "  3. Keep in DotRun but add to .gitignore"
       ""
       "How would you like to proceed?"
```

### Conflicting aliases

```
Agent: "Warning: Alias conflicts detected"
       ""
       "Existing DotRun aliases:"
       "  gs='git switch' (from 05-git.aliases)"
       ""
       "Migration source:"
       "  gs='git status' (from ~/.bash_profile)"
       ""
       "Options:"
       "  1. Keep existing DotRun alias"
       "  2. Replace with migrated alias"
       "  3. Rename migrated alias (suggest: gst)"
```

## Error Recovery

### Migration interrupted

```bash
# If migration fails mid-process:
Agent: "Migration interrupted!"
       ""
       "Created so far:"
       "  ✓ configs/01-paths.config"
       "  ✓ configs/02-env.config"
       "  ✗ configs/03-api-keys.config (failed)"
       ""
       "Options:"
       "  1. Resume from last successful step"
       "  2. Rollback all changes"
       "  3. Keep partial migration"
       ""
       "Original file is unchanged: ~/.bash_profile"
       "Backup is safe: ~/.bash_profile.bk.20260204-143022"
```

### Rollback procedure

```bash
# Remove created files
dr -c remove 01-paths
dr -c remove 02-env
dr -a remove 05-git
# ... etc

# Restore original if needed
cp ~/.bash_profile.bk.20260204-143022 ~/.bash_profile

echo "✓ Rollback complete"
echo "✓ Original file restored"
```

## Tips for Best Results

### Before migration

1. Close other shells (avoid conflicting loads)
2. Commit current DotRun state to git
3. Review what's in the file to migrate
4. Consider splitting large files into multiple migrations

### During migration

1. Read the plan carefully before approving
2. Question anything unclear
3. Request changes to categorization if needed
4. Test thoroughly before cleanup

### After migration

1. Open a fresh shell to test
2. Keep backup for at least 30 days
3. Document any manual adjustments needed
4. Update shell startup files to source ~/.drrc instead

## Migration Best Practices

### Load Order Priority

1. **Critical dependencies first** - PATH, fundamental env vars
2. **Tools that modify environment** - rbenv, pyenv, nvm
3. **User preferences** - EDITOR, LANG, PS1
4. **Convenience items** - aliases, functions

### File Organization

1. **Group by purpose** - git aliases together, docker aliases together
2. **Prefix with numbers** - ensures load order (01-, 05-, 10-)
3. **Name descriptively** - "05-git" not "aliases1"
4. **Keep scripts focused** - one script, one purpose

### Security Considerations

1. **Never commit secrets** - add api-keys.config to .gitignore
2. **Review permissions** - scripts should be 755, configs 644
3. **Audit what's migrated** - don't blindly import everything
4. **Rotate keys after migration** - especially if backed up

---

**End of Migration Workflow Reference**

This workflow must be followed exactly for all file migration requests.
