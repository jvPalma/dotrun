# Git Branch Cleanup Documentation

## Overview

The Git Branch Cleanup script is an intelligent, interactive tool designed to help developers efficiently manage and clean up local and remote Git branches. It's particularly optimized for teams using GitHub's "squash and merge" workflow, automatically detecting and categorizing branches that have been merged through various methods.

## Features

### 🎯 **Core Functionality**
- **Interactive Branch Selection** - Visual branch management with emoji indicators
- **Smart Merge Detection** - Detects both regular merges and squash-merges
- **Stash Management** - Automatically handles uncommitted changes
- **Remote Branch Deletion** - Option to delete both local and remote branches
- **Safe Restoration** - Always returns to your original branch
- **Graceful Interruption** - Handles Ctrl+C and unexpected exits

### 🧠 **Intelligent Branch Classification**

| Icon | Type | Description |
|------|------|-------------|
| 👉 | Current | The branch you're currently working on |
| ✅ | Merged | Branches merged via regular Git merge |
| 📦 | Squash-Merged | Branches merged via GitHub "squash and merge" |
| ⬆️ | Ahead | Branches with commits not in master |
| ⬇️ | Behind | Branches missing commits from master |
| 🔀 | Diverged | Branches both ahead and behind master |
| 🆕 | Untracked | Local-only branches with no remote |

### 🌐 **Remote Status Indicators**

| Symbol | Meaning |
|--------|---------|
| 💻🌐 | Local + Remote exists |
| 💻🌐(gone) | Local exists, remote deleted |
| 💻⬛ | Local only, no remote |



## Examples

### Example 1: Basic Cleanup

```bash
$ /home/user/.config/dotrun/bin/git/branchCleanup.sh

🧹 Starting branch cleanup
   Current branch: feature/my-work
   Default branch: master

🔄 Switching to master
📥 Pulling latest changes
🎯 Starting interactive branch cleanup...

Found 5 branches. Numbers 1-9 can be used for quick selection

- 👉 feature/my-work Current branch
    2 hours ago • John Doe • ↑3 • (💻🌐)
1) 🔵 📦 feature/completed-task
    3 days ago • John Doe • (💻⬛)
2) 🔵 ✅ bugfix/urgent-fix  
    1 week ago • Jane Smith • (💻🌐(gone))
3) ⚫ ⬆️ feature/in-progress
    2 days ago • John Doe • ↑5 • (💻🌐)

Currently selected branches:
  Total: 2 branches

Choice [c]: c

```
---

```bash

📋 Deletion Summary:
────────────────────────────────────────────
📦 feature/completed-task
   Last commit: 3 days ago • John Doe
   Remote status: 💻⬛
   📦 Squash-merged into master

✅ bugfix/urgent-fix
   Last commit: 1 week ago • Jane Smith  
   Remote status: 💻🌐(gone)
   ✅ Merged into master

Total: 2 branch(es) selected for deletion

Delete these local branches? (y/N): y

Also delete remote branches on origin? (y/N): y

```
---

```bash

🗑️  Deleting branches...

✓ Deleted local branch: feature/completed-task
  ℹ Remote branch origin/feature/completed-task does not exist
✓ Deleted local branch: bugfix/urgent-fix
  ✓ Deleted remote branch: origin/bugfix/urgent-fix

✅ Branch cleanup completed!
Local branches - Successfully deleted: 2
Remote branches - Successfully deleted: 1

🌿 Pruning remote tracking branches
🔄 Restoring original branch: feature/my-work
✅ Branch cleanup completed

```

### Example 2: With Uncommitted Changes

```bash
$ /home/user/.config/dotrun/bin/git/branchCleanup.sh

🧹 Starting branch cleanup
   Current branch: feature/my-work
   Default branch: master

📦 Uncommitted changes detected. Stashing them for safekeeping...
✓ Changes stashed successfully
   Stash message: Auto-stash by branch cleanup script on 2025-06-19 14:30:15

# ... cleanup process ...

🔄 Restoring original branch: feature/my-work
📦 Restoring stashed changes...
✓ Stashed changes restored
✅ Branch cleanup completed
```


## Usage

### Basic Usage
```bash
# Run from any Git repository
drun branchCleanup
```

### Workflow
1. **Preparation Phase**
   - Detects current branch
   - Switches to master and pulls latest changes
   - Automatically stashes any uncommitted changes

2. **Analysis Phase**
   - Scans all local branches
   - Determines merge status (regular, squash, or unmerged)
   - Calculates ahead/behind commit counts
   - Checks remote branch existence

3. **Interactive Selection**
   - Displays categorized branch list
   - Pre-selects merged and squash-merged branches
   - Allows manual selection/deselection

4. **Deletion Phase**
   - Confirms deletion with summary
   - Optionally deletes remote branches
   - Provides detailed progress feedback

5. **Cleanup Phase**
   - Restores original branch
   - Restores stashed changes
   - Prunes stale remote tracking references

## Interactive Commands

### Main Menu Options

| Key | Action | Description |
|-----|--------|-------------|
| `1-9` | Toggle Branch | Quick selection by number |
| `a` | Select All | Select all non-current branches |
| `m` | Merged Only | Select only merged branches (default) |
| `n` | None | Clear all selections |
| `s` | Individual | Enter individual branch selection mode |
| `c` | Continue | Proceed with current selection |
| `q` | Quit | Exit without changes |

### Individual Selection Mode

- **Branch Name Matching**: Type partial branch names
- **Number Selection**: Use branch numbers for quick access
- **Fuzzy Matching**: Supports partial string matching
- **Multiple Matches**: Shows disambiguation when needed

## Advanced Features

### Squash-Merge Detection Algorithm

The script uses sophisticated logic to detect squash-merged branches:

1. **Unique Commits Check**: Branch has commits not in master
2. **Remote Branch Status**: Remote branch was deleted (strong indicator)
3. **Commit Message Analysis**: Looks for similar patterns in recent master commits
4. **PR Reference Detection**: Identifies pull request patterns in master history

### Stash Management

Automatically handles uncommitted changes:

```bash
# Detects changes in:
- Modified tracked files
- Untracked files
- Staged changes

# Creates timestamped stash:
"Auto-stash by branch cleanup script on 2025-06-19 14:30:15"

# Restores changes after cleanup
```

### Safety Features

- **Branch Protection**: Never deletes master, main, or develop
- **Current Branch Protection**: Cannot delete the branch you're working on
- **Graceful Interruption**: Ctrl+C safely restores state
- **Error Handling**: Continues operation despite individual failures
- **Confirmation Steps**: Multiple confirmation prompts

## Technical Architecture

### File Structure

```
~/.config/dotrun/
├── bin/git/branchCleanup.sh              # Main entry point
├── helpers/bash-interactive-cleanup.sh   # Core interactive logic
├── helpers/git.sh                        # Git utility functions
└── docs/git/branchCleanup.md            # This documentation
```

### Key Functions

#### Entry Point (`branchCleanup.sh`)
- Validates Git repository
- Switches to master branch
- Pulls latest changes
- Calls interactive cleanup

#### Core Logic (`bash-interactive-cleanup.sh`)
- `get_branch_info()` - Analyzes branch status and metadata
- `is_branch_merged()` - Detects regular merges
- `is_branch_squash_merged()` - Detects squash merges
- `interactive_branch_selection()` - Handles user interaction
- `delete_branches()` - Performs deletion operations

### Data Flow

```
1. Branch Analysis
   ├── Parse `git branch -vv` output
   ├── Extract ahead/behind counts
   ├── Check remote existence
   ├── Determine merge status
   └── Format display information

2. User Interaction
   ├── Display categorized branches
   ├── Handle selection commands
   ├── Update selection state
   └── Show confirmation summary

3. Deletion Process
   ├── Delete local branches
   ├── Delete remote branches (optional)
   ├── Track success/failure counts
   └── Report results
```

## Configuration

### Environment Variables

- `DRUN_CONFIG` - Path to DotRun configuration directory
- `DELETE_REMOTE_BRANCHES` - Controls remote deletion (set by user prompt)

### Customizable Elements

```bash
# Colors (in bash-interactive-cleanup.sh)
MERGED_COLOR=$GREEN
SQUASH_MERGED_COLOR=$GREEN
AHEAD_COLOR=$BLUE
BEHIND_COLOR=$MAGENTA

# Icons
MERGED_ICON="✅ "
SQUASH_MERGED_ICON="📦 "
CURRENT_ICON="👉 "
```

## Error Handling

### Common Scenarios

1. **Merge Conflicts During Stash**
   - User prompted to resolve manually
   - Option to continue or abort

2. **Remote Deletion Failures**
   - Individual failures don't stop process
   - Detailed error reporting

3. **Branch Restoration Issues**
   - Fallback to manual instructions
   - Clear error messages

### Exit Codes

- `0` - Success
- `1` - General error (not in Git repo, user cancellation)
- Signal handling for graceful interruption

## Performance Considerations

### Optimizations

- **Batch Operations**: Single `git branch -vv` call for all data
- **Efficient Parsing**: Minimal subprocess calls
- **Lazy Evaluation**: Remote checks only when needed
- **Temp File Management**: Automatic cleanup

### Scalability

- Handles repositories with 100+ branches efficiently
- Color output adapts to terminal capabilities
- Responsive to user interruption

## Best Practices

### When to Use

✅ **Ideal Scenarios**:
- After completing feature work
- Regular maintenance (weekly/monthly)
- Before major development phases
- After team merge sessions

❌ **Avoid When**:
- Uncommitted critical changes
- During active development
- On shared/CI machines
- With unstable network connectivity

### Workflow Integration

```bash
# Typical development cycle
git checkout feature/my-branch
# ... do work ...
git push origin feature/my-branch
# ... create PR, get approved, squash merge ...

# Later cleanup
drun branchCleanup
# Automatically detects and offers to delete feature/my-branch
```

## Troubleshooting

### Common Issues

#### "Not in a git repository"
```bash
# Ensure you're in a Git repository
cd /path/to/your/repo
pwd
git status
```

#### "Failed to delete remote branch"
```bash
# Check permissions and network
git remote -v
git push origin --delete branch-name  # Manual test
```

#### "Could not restore stashed changes"
```bash
# Manual stash management
git stash list
git stash pop  # Or git stash apply
```

### Debug Mode

```bash
# Enable verbose output
set -x
~/.config/dotrun/bin/git/branchCleanup.sh
```


## Dependencies

### Required Tools
- `bash` (4.0+)
- `git` (2.0+)
- `grep`, `awk`, `sed` (standard Unix tools)

### Required Scripts
- `$DRUN_CONFIG/helpers/git.sh` - Git utility functions

### Optional Enhancements
- Terminal with emoji support
- Color-capable terminal
- Bash completion support

## Contributing

To enhance or modify the branch cleanup script:

1. **Test Changes**: Always test in a safe repository
2. **Maintain Compatibility**: Ensure backward compatibility
3. **Update Documentation**: Reflect changes in this file
4. **Error Handling**: Add appropriate error cases
5. **User Experience**: Maintain intuitive interface

## Related Documentation

- [Git Branch Management](./cleanup.md) - Basic cleanup concepts
- [DotRun Configuration](../README.md) - Overall system setup
- [Git Utilities](./git-utils.md) - Shared Git functions

---

*Last updated: December 2024*
*Script location: `/home/user/.config/dotrun/bin/git/branchCleanup.sh`*
