# prStack — Git PR Stack Management Tool

A sophisticated workflow tool for managing stacked pull requests, enabling efficient development of large features that require multiple dependent PRs. Automates the creation, maintenance, and cleanup of PR stacks with intelligent branch management.

## Description

`prStack` streamlines the development of complex features that need to be split across multiple pull requests. It handles the intricate git operations required to maintain a stack of dependent branches, automatically managing rebases, updates, and cleanup as PRs get merged upstream.

Perfect for teams that need to break down large features into reviewable chunks while maintaining a clean git history and manageable review process.

## Key Concepts

### PR Stack Workflow
A PR stack is a series of dependent branches where:
1. **Base Branch**: Each PR is based on the previous branch in the stack
2. **Sequential Merging**: PRs are merged in order from bottom to top
3. **Automatic Updates**: Stack automatically updates as lower PRs merge
4. **Clean History**: Maintains linear history throughout the process

### Stack States
- **Initial**: First branch created from default branch
- **Extended**: Additional branches added to the stack
- **Updating**: Stack being rebalanced after merges
- **Final**: All PRs merged, cleanup in progress

## Usage

### Command Overview

```bash
drun git/prStack <command> [args...]
```

### Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `init` | Initialize a new PR stack | `prStack init <new-branch>` |
| `next` | Create next branch in stack | `prStack next <next-branch>` |
| `update` | Update stack after merges | `prStack update` |
| `final` | Finalize and clean up stack | `prStack final` |

## Commands in Detail

### Initialize Stack: `init`

Creates the first branch in a new PR stack from the default branch.

```bash
# Start a new PR stack for a multi-part feature
drun git/prStack init feature-part1

# Creates:
# - New branch 'feature-part1' from master/main
# - Stack tracking for future operations
# - Clean slate for feature development
```

**What it does:**
- Identifies repository default branch (master/main)
- Creates new branch from latest default branch
- Initializes stack tracking metadata
- Switches to the new branch for development

### Extend Stack: `next`

Adds the next branch to the existing stack, based on the current branch.

```bash
# Continue the stack with the next logical piece
drun git/prStack next feature-part2

# Creates 'feature-part2' based on current 'feature-part1'
# Maintains dependency chain for proper PR workflow
```

**What it does:**
- Creates new branch from current branch HEAD
- Updates stack tracking to include new branch
- Maintains parent-child relationship
- Switches to new branch for continued development

### Update Stack: `update`

Intelligently updates the stack after PRs have been merged upstream.

```bash
# After feature-part1 PR is merged, update the stack
drun git/prStack update

# Automatically:
# - Detects merged branches
# - Rebases dependent branches onto new base
# - Updates tracking information
# - Resolves conflicts if needed
```

**What it does:**
- Scans for merged stack branches
- Rebases remaining branches onto updated base
- Handles merge conflicts interactively
- Updates stack metadata
- Provides progress feedback

### Finalize Stack: `final`

Completes the stack workflow and performs cleanup.

```bash
# After all PRs are merged, clean up the stack
drun git/prStack final

# Removes tracking, cleans up branches, returns to default
```

**What it does:**
- Verifies all stack PRs are merged
- Cleans up local stack branches
- Removes stack tracking metadata
- Returns to default branch
- Provides completion summary

## Workflow Examples

### Complete Feature Development Cycle

```bash
# 1. Start a new feature requiring multiple PRs
git checkout master
drun git/prStack init auth-system-base

# Develop foundational authentication code
git add . && git commit -m "Add base authentication framework"
git push -u origin auth-system-base
# Create PR: auth-system-base → master

# 2. Add OAuth integration on top
drun git/prStack next auth-oauth-integration

# Develop OAuth functionality
git add . && git commit -m "Implement OAuth provider integration"
git push -u origin auth-oauth-integration  
# Create PR: auth-oauth-integration → auth-system-base

# 3. Add UI components
drun git/prStack next auth-ui-components

# Develop authentication UI
git add . && git commit -m "Add login/logout UI components"
git push -u origin auth-ui-components
# Create PR: auth-ui-components → auth-oauth-integration

# 4. After auth-system-base PR is approved and merged
drun git/prStack update
# Automatically rebases auth-oauth-integration onto master
# Updates auth-ui-components to be based on updated auth-oauth-integration

# 5. Continue pattern as each PR gets merged
# When auth-oauth-integration merges:
drun git/prStack update

# 6. After all PRs are merged
drun git/prStack final
# Clean up all tracking and return to master
```

### Handling Complex Updates

```bash
# When multiple PRs merge simultaneously
drun git/prStack update

# If conflicts arise during update:
# 1. Script pauses for manual conflict resolution
# 2. Resolve conflicts in affected files
# 3. Run: git add . && git rebase --continue
# 4. Script automatically continues with next branch

# For problematic updates:
git rebase --abort  # If needed to cancel
drun git/prStack update  # Try again
```

## Advanced Features

### Intelligent Merge Detection
- **Merge Commit Detection**: Recognizes when stack branches are merged
- **Squash Merge Handling**: Handles GitHub squash-and-merge workflow
- **Branch Cleanup**: Automatically removes merged branches from stack

### Conflict Resolution
- **Interactive Rebasing**: Pauses for manual conflict resolution
- **Progress Tracking**: Shows which branches have been updated
- **Recovery Options**: Provides abort/retry mechanisms

### Stack Validation
- **Dependency Verification**: Ensures proper branch relationships
- **State Consistency**: Validates stack integrity before operations
- **Error Recovery**: Handles edge cases gracefully

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DRUN_CONFIG` | DotRun configuration directory | `~/.config/dotrun` |
| `GIT_DEFAULT_BRANCH` | Override default branch detection | Auto-detected |

### Stack Metadata

Stack information is stored in:
- `~/.prstack-state` - Current stack configuration
- `~/.prstack-branches` - Branch dependency mapping

## Dependencies

### Required Tools
- **git** (2.0+) with rebase support
- **bash** (4.0+) for advanced scripting features

### Required Scripts
- `$DRUN_CONFIG/helpers/git.sh` - Git utility functions
- `$DRUN_CONFIG/helpers/pkg.sh` - Package validation
- `$DRUN_CONFIG/helpers/prStack.sh` - Core stack logic

## Error Handling

### Common Scenarios

| Issue | Cause | Resolution |
|-------|-------|------------|
| Rebase conflicts | Overlapping changes | Resolve manually, continue rebase |
| Missing branches | Branch deleted externally | Run `update` to resync |
| Stack corruption | Manual git operations | Use `final` to clean up and restart |

### Recovery Commands

```bash
# Reset stack state if corrupted
rm ~/.prstack-* && drun git/prStack final

# Abort problematic rebase
git rebase --abort

# Manual cleanup if automated cleanup fails
git checkout master
git branch -D feature-part1 feature-part2  # etc.
```

## Best Practices

### Stack Planning
1. **Logical Separation**: Each branch should represent a complete, reviewable unit
2. **Minimal Dependencies**: Reduce coupling between stack levels
3. **Clear Naming**: Use consistent naming convention (feature-part1, feature-part2)

### Development Workflow
1. **Commit Frequently**: Regular commits make rebasing easier
2. **Test Each Level**: Ensure each PR in stack works independently
3. **Update Regularly**: Run `update` after each merge to stay current

### Review Process
1. **Bottom-Up Reviews**: Review and merge from base of stack upward
2. **Clear PR Descriptions**: Explain dependencies and stack position
3. **Coordinate Timing**: Merge stack PRs in sequence to avoid conflicts

## Integration

### GitHub Workflow
```bash
# Create stack PRs with proper base branches
gh pr create --base master --title "Auth: Base framework"
gh pr create --base auth-system-base --title "Auth: OAuth integration"  
gh pr create --base auth-oauth-integration --title "Auth: UI components"
```

### CI/CD Considerations
- **Test Dependencies**: Ensure CI tests understand stack dependencies
- **Deployment Coordination**: Plan deployments around stack completion
- **Branch Protection**: Configure rules that work with stack workflow

## Troubleshooting

### Common Issues

#### Stack Gets Out of Sync
```bash
# Symptoms: Update fails, branches show as diverged
# Solution: Manual intervention may be required
git checkout master && git pull
drun git/prStack final  # Clean up
# Restart with fresh stack
```

#### Rebase Conflicts During Update
```bash
# Symptoms: Git stops with conflict messages
# Solution: Resolve conflicts manually
git status  # See conflicted files
# Edit files to resolve conflicts
git add .
git rebase --continue
# prStack will continue automatically
```

#### Lost Stack State
```bash
# Symptoms: Commands fail with "no active stack"
# Solution: Verify stack metadata files
ls ~/.prstack-*
# If missing, use manual cleanup:
drun git/prStack final
```

## Performance

### Optimization Features
- **Batch Operations**: Groups git commands for efficiency
- **Smart Rebasing**: Only rebases branches that need updating
- **Minimal Metadata**: Lightweight tracking system

### Scalability
- **Large Stacks**: Handles 10+ branches efficiently
- **Complex Repos**: Works in repositories with hundreds of branches
- **Team Usage**: Multiple developers can manage separate stacks

## Related Tools

- **branchSlice** - Create feature branches for stack building
- **branchCleanup** - Post-stack cleanup and maintenance
- **prDescription** - Generate descriptions for stack PRs
- **GitHub CLI** - PR creation and management integration

---

*Stack management made simple. Build complex features with confidence.*