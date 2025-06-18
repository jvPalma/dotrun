# branchGetSlicedCode — copy code from a sliced branch to current working tree

### Synopsis

`branchGetSlicedCode`

### Description

Copies the code from the previously sliced branch (stored in `~/.sliced-pr`) into your current working tree without changing your current branch or HEAD. This is useful when you want to bring changes from a clean sliced branch back to your development branch, or when you need to reference or compare code between branches.

**Technical Details:**
- Checks out the sliced branch files into the working tree only
- Keeps your current HEAD/branch unchanged  
- Resets the index to avoid staging conflicts
- Preserves your current branch context

### Use Cases

#### 1. Bring Clean Changes Back to Development Branch
```bash
# You created a clean branch and made some fixes
git checkout feature/messy-development
drun branchSlice feature/clean-fixes
# ... made some improvements on clean branch ...
git commit -m "Clean fixes"

# Now bring those fixes back to development branch
drun branchCoSliced  # Back to feature/messy-development
drun branchGetSlicedCode  # Copy the fixes to working tree
git add .
git commit -m "Apply fixes from clean branch"
```

#### 2. Cherry-Pick Changes from Sliced Branch
```bash
# Create clean branch with multiple changes
git checkout feature/complex-work
drun branchSlice feature/ready-for-review
git add component1/ component2/ component3/
git commit -m "Multiple components ready"

# Return to development and get only some changes
drun branchCoSliced
drun branchGetSlicedCode
# Now selectively add what you want
git add component1/
git commit -m "Add component1 to development branch"
```

#### 3. Compare Code Between Branches
```bash
# See what changed in the sliced branch
git checkout feature/original-work
drun branchGetSlicedCode
git diff  # Shows differences between branches
git checkout .  # Discard the copied changes
```

#### 4. Resolve Merge Conflicts with Clean Version
```bash
# Your branch has conflicts with master
git checkout feature/conflicted-branch
git merge master  # Conflicts occur

# Get clean version from sliced branch
drun branchGetSlicedCode
# Manually resolve using the clean code
git add resolved-files/
git commit -m "Resolve conflicts with clean implementation"
```

### Advanced Workflows

#### Iterative Development Pattern
```bash
# Start development
git checkout -b feature/iterative-work

# Create clean snapshot
drun branchSlice feature/snapshot-v1
git add .
git commit -m "Version 1"

# Continue development with experiments
drun branchCoSliced
# ... experiment with different approaches ...

# Get back to clean state when needed
drun branchGetSlicedCode
# Working tree now has the clean version 1 code
```

#### Code Review Integration
```bash
# Reviewer suggests changes on your clean PR branch
git checkout feature/pr-branch
# ... reviewer adds commits directly ...

# Bring review changes back to development
git checkout feature/development-branch
echo "feature/pr-branch" > ~/.sliced-pr  # Manually set reference
drun branchGetSlicedCode
git add .
git commit -m "Apply reviewer suggestions"
```

#### Cross-Branch Development
```bash
# Working on feature A
git checkout feature/feature-a
# ... implement feature A ...

# Need similar code for feature B
git checkout feature/feature-b
echo "feature/feature-a" > ~/.sliced-pr  # Set reference
drun branchGetSlicedCode
# Adapt the code for feature B
git add modified-files/
git commit -m "Adapt feature A code for feature B"
```

### Safety Considerations

#### Pre-Check Working Tree
```bash
# Ensure clean working tree before copying
git status
# If there are changes, decide whether to stash or commit them
git stash push -m "Save work before copying sliced code"
drun branchGetSlicedCode
```

#### Verify Sliced Branch Reference
```bash
# Check what branch will be copied from
cat ~/.sliced-pr

# Verify the branch exists
git branch --list "$(cat ~/.sliced-pr)"
git show "$(cat ~/.sliced-pr)" --name-only --pretty=format:
```

#### Backup Current State
```bash
# Create a backup branch before copying
git checkout -b backup-before-copy
git checkout -  # Return to previous branch
drun branchGetSlicedCode
```

### Integration with Git Workflow

#### Stash Integration
```bash
# Save current work, get sliced code, then decide
git stash push -m "Current work"
drun branchGetSlicedCode
# Examine the copied code
git diff HEAD
# Decide whether to keep or restore
git stash pop  # Restore your work if needed
```

#### Selective Application
```bash
# Get sliced code and selectively apply
drun branchGetSlicedCode
git add -p  # Interactively stage desired changes
git checkout .  # Discard unselected changes
git commit -m "Apply selected changes from sliced branch"
```

### Error Handling and Troubleshooting

#### Common Issues

**No sliced branch reference:**
```bash
# Check if reference file exists
ls -la ~/.sliced-pr
# If missing, manually create reference
echo "your-branch-name" > ~/.sliced-pr
drun branchGetSlicedCode
```

**Sliced branch doesn't exist:**
```bash
# Verify branch exists
SLICED_BRANCH=$(cat ~/.sliced-pr)
git show "$SLICED_BRANCH" 2>/dev/null || echo "Branch doesn't exist"
```

**Working tree conflicts:**
```bash
# If working tree has uncommitted changes
git status
# Either commit or stash them first
git stash push -m "Before getting sliced code"
drun branchGetSlicedCode
```

#### Manual Recovery
```bash
# If command fails, manual approach:
SLICED_BRANCH=$(cat ~/.sliced-pr)
git checkout "$SLICED_BRANCH" -- .
git reset  # Unstage everything
```

### Comparison with Similar Commands

| Command | Effect | Use Case |
|---------|--------|----------|
| `git checkout branch -- .` | Copy all files from branch | Manual file copying |
| `git cherry-pick commit` | Apply specific commits | When you know exact commits |
| `drun branchGetSlicedCode` | Copy from saved reference | Part of slicing workflow |
| `git merge branch` | Merge entire branch | When you want full history |

### Performance and Limitations

#### Performance Characteristics
- **Fast**: Only copies working tree files
- **Lightweight**: No branch switching overhead
- **Selective**: Can be combined with partial staging

#### Limitations
- **Overwrites working tree**: All current changes are replaced
- **No conflict resolution**: Files are simply overwritten
- **Index reset**: Staged changes are unstaged
- **Reference dependency**: Requires valid `.sliced-pr` reference

### Best Practices

1. **Clean working tree first**: Commit or stash changes before copying
2. **Verify reference**: Check `~/.sliced-pr` before running
3. **Selective staging**: Use `git add -p` after copying for fine control
4. **Backup strategy**: Create backup branches for important work
5. **Document workflow**: Track which sliced branch code came from

### Example Complete Workflow

#### Feature Development with Code Sharing
```bash
# 1. Start development
git checkout -b feature/user-auth

# 2. Create clean version
drun branchSlice feature/auth-clean
git add src/auth/
git commit -m "Authentication system"

# 3. Continue development on original branch
drun branchCoSliced
# ... more experimental work ...

# 4. Need the clean code back in development
drun branchGetSlicedCode
git add src/auth/  # Only add the files you want
git commit -m "Integrate clean auth implementation"

# 5. Continue with hybrid approach
# ... keep developing ...
```

### See Also

- [branchSlice.md](./branchSlice.md) - Create the sliced branch with clean code
- [branchCoSliced.md](./branchCoSliced.md) - Return to the original branch
- [Git Workflow Guide](./cleanup.md) - Overall Git workflow best practices