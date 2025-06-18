# branchSlice — create a clean branch with current changes

### Synopsis

`branchSlice <new-branch>`

### Description

Creates a new branch based on the repository's default branch (master/main) while preserving your current work-in-progress changes. This is particularly useful for creating clean, reviewable branches from messy development branches or for separating concerns during development.

**Workflow:**
1. Saves the current branch name to `~/.sliced-pr` for later reference
2. Creates/resets `<new-branch>` from the repository's default branch
3. Copies all staged and unstaged changes from the original branch
4. Switches to the new branch with your changes ready to commit

### Arguments

| Position | Name | Description |
|----------|------|-------------|
| 1 | new-branch | Name of the clean branch to create |

### Use Cases

#### 1. Clean Up Messy Development Branch
```bash
# You've been experimenting on a feature branch
git checkout feature/experimental-work
# ... lots of commits, reverts, and WIP changes ...

# Extract clean changes for review
drun branchSlice feature/login-system-clean

# Now you have a clean branch with just your current changes
git add .
git commit -m "Add login system with OAuth integration"
```

#### 2. Split Large Feature into Smaller PRs
```bash
# Working on a large feature
git checkout feature/user-management
# ... implemented multiple related features ...

# Create focused branches for each component
drun branchSlice feature/user-authentication
git add src/auth/
git commit -m "Add user authentication system"

# Switch back and slice another component
drun branchCoSliced  # Returns to original branch
drun branchSlice feature/user-profiles  
git add src/profiles/
git commit -m "Add user profile management"
```

#### 3. Emergency Hotfix from Development Branch
```bash
# You're in the middle of development
git checkout feature/new-dashboard
# ... working on new features ...

# Urgent bug discovered - need clean branch for hotfix
drun branchSlice hotfix/security-patch
# Remove feature changes, keep only the bug fix
git add src/security/
git commit -m "Fix authentication vulnerability"
```

#### 4. Code Review Preparation
```bash
# Your development branch has messy history
git checkout feature/api-refactor
git log --oneline  # Shows: "WIP", "temp", "debug", "revert", etc.

# Create clean branch for PR
drun branchSlice feature/api-refactor-pr
git add .
git commit -m "Refactor API endpoints for better performance

- Optimize database queries
- Add response caching
- Improve error handling"
```

### Integration with Related Commands

#### Complete Workflow Example
```bash
# 1. Start with messy development
git checkout feature/complex-feature

# 2. Slice out clean branch
drun branchSlice feature/auth-component

# 3. Commit clean changes
git add src/auth/
git commit -m "Add authentication component"
git push origin feature/auth-component

# 4. Return to original work
drun branchCoSliced

# 5. Continue development or slice more components
drun branchSlice feature/ui-components
# ... continue workflow ...
```

#### Working with Sliced Branches
```bash
# After slicing, you can:

# Get back to the original branch
drun branchCoSliced

# Copy code from the sliced branch to current working tree
drun branchGetSlicedCode

# Check what branch was sliced
cat ~/.sliced-pr
```

### Advanced Scenarios

#### Multiple Slice Operations
```bash
# Original feature branch
git checkout feature/mega-feature

# Slice authentication part
drun branchSlice feature/auth-only
git add src/auth/
git commit -m "Authentication system"

# Return and slice UI part  
drun branchCoSliced
drun branchSlice feature/ui-only
git add src/components/
git commit -m "User interface components"

# Return and slice API part
drun branchCoSliced  
drun branchSlice feature/api-only
git add src/api/
git commit -m "API endpoints"
```

#### Collaborative Development
```bash
# Developer A slices a clean branch for review
git checkout feature/shared-work
drun branchSlice feature/ready-for-review
git push origin feature/ready-for-review

# Developer B can work with the sliced branch
git checkout feature/ready-for-review
# ... make review comments, small fixes ...

# Developer A gets back to original work
drun branchCoSliced
# ... continues development ...
```

### Default Branch Detection

The script automatically detects your repository's default branch:

```bash
# Checks in this order:
# 1. Remote HEAD reference (git symbolic-ref refs/remotes/origin/HEAD)
# 2. GIT_DEFAULT_BRANCH environment variable  
# 3. Falls back to 'master'

# Override default branch detection
GIT_DEFAULT_BRANCH=main drun branchSlice feature/new-work
```

### Safety Features

- **Non-destructive**: Original branch and changes are preserved
- **Rollback capability**: Can always return via `branchCoSliced`
- **Change preservation**: All modifications (staged/unstaged) are copied
- **Reference tracking**: Original branch name stored for easy access

### Common Patterns

#### Daily Development Workflow
```bash
# Morning: start messy development
git checkout -b feature/daily-work

# Throughout day: experiment, try things, make WIP commits
# ... lots of experimental commits ...

# End of day: create clean branch for tomorrow's review
drun branchSlice feature/ready-for-review
git add .
git commit -m "Implement feature X with proper error handling"
```

#### Feature Branch Cleanup
```bash
# Before creating PR, clean up the branch
git checkout feature/messy-implementation
drun branchSlice feature/clean-implementation

# Add only the files you want in the PR
git add src/feature.js tests/feature.test.js
git commit -m "Add feature X with comprehensive tests"

# Push clean branch for PR
git push origin feature/clean-implementation
```

### Troubleshooting

#### Common Issues

**Changes not copied correctly:**
```bash
# Ensure all changes are visible
git status  # Check for staged/unstaged changes
git stash list  # Check for stashed changes
```

**Wrong default branch detected:**
```bash
# Check current default branch detection
git symbolic-ref refs/remotes/origin/HEAD

# Set correct default branch
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
```

**Cannot return to original branch:**
```bash
# Check sliced branch reference
cat ~/.sliced-pr

# Manually return if needed
git checkout $(cat ~/.sliced-pr)
```

### See Also

- [branchCoSliced.md](./branchCoSliced.md) - Return to the original sliced branch
- [branchGetSlicedCode.md](./branchGetSlicedCode.md) - Copy sliced branch code to working tree
- [branchCleanup.md](./branchCleanup.md) - Clean up branches after slicing workflow