# branchCoSliced — return to the original sliced branch

### Synopsis

`branchCoSliced`

### Description

Returns to the original branch that was saved when you used `branchSlice`. This command reads the branch name stored in `~/.sliced-pr` and checks it out, allowing you to easily switch back to your original development work after creating a clean branch for review or deployment.

### Use Cases

#### 1. Return After Creating Clean Branch

```bash
# Create a clean branch for PR
git checkout feature/messy-development
dr branchSlice feature/clean-for-review
git add .
git commit -m "Clean implementation ready for review"
git push origin feature/clean-for-review

# Return to continue messy development
dr branchCoSliced
# Now back on feature/messy-development
```

#### 2. Multiple Slice Operations

```bash
# Original complex feature
git checkout feature/large-feature

# Slice first component
dr branchSlice feature/auth-component
git add src/auth/
git commit -m "Authentication system"

# Return to original and slice another component
dr branchCoSliced  # Back to feature/large-feature
dr branchSlice feature/ui-component
git add src/ui/
git commit -m "UI components"

# Return again to continue development
dr branchCoSliced  # Back to feature/large-feature again
```

#### 3. Emergency Context Switching

```bash
# Working on feature development
git checkout feature/new-dashboard

# Create hotfix branch quickly
dr branchSlice hotfix/urgent-security-fix
# ... make urgent changes ...
git add .
git commit -m "Fix security vulnerability"
git push origin hotfix/urgent-security-fix

# Immediately return to feature work
dr branchCoSliced
# Back to feature/new-dashboard development
```

### Workflow Integration

#### Standard Development Cycle

```bash
# Day 1: Start feature work
git checkout -b feature/user-management
# ... implement and experiment ...

# Day 1 End: Create clean branch for review
dr branchSlice feature/user-management-pr
git add src/
git commit -m "Add user management system"
git push origin feature/user-management-pr

# Day 2: Return to development work
dr branchCoSliced
# Continue working on feature/user-management
```

#### Code Review Response

```bash
# You have a PR under review
git checkout feature/clean-for-review
# Reviewer asks for changes

# Return to development branch to make changes
dr branchCoSliced
# Make the requested changes

# Create new clean version
dr branchSlice feature/clean-for-review-v2
git add .
git commit -m "Address review feedback"
```

### Safety and Error Handling

#### Checking Saved Branch

```bash
# See what branch is saved before switching
cat ~/.sliced-pr

# Only switch if file exists and branch is valid
if [[ -f ~/.sliced-pr && -n "$(cat ~/.sliced-pr)" ]]; then
  dr branchCoSliced
fi
```

#### Branch Validation

```bash
# Verify the saved branch still exists
git branch --list "$(cat ~/.sliced-pr)"

# Check if it's a remote branch
git branch -r --list "origin/$(cat ~/.sliced-pr)"
```

### Advanced Usage

#### Scripted Workflows

```bash
#!/bin/bash
# automated_slice_and_return.sh

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# Create clean branch
dr branchSlice "clean-$(date +%Y%m%d)"
git add .
git commit -m "Automated clean branch creation"

# Return to original work
dr branchCoSliced

echo "Created clean branch, returned to $CURRENT_BRANCH"
```

#### Integration with Other Tools

```bash
# Create clean branch and open PR, then return
git checkout feature/my-work
dr branchSlice feature/my-work-pr
git add .
git commit -m "Ready for review"
git push origin feature/my-work-pr

# Create PR via GitHub CLI
gh pr create --title "Add new feature" --body "Description here"

# Return to development work
dr branchCoSliced
```

### Troubleshooting

#### Common Issues

**No sliced branch reference:**

```bash
# Check if ~/.sliced-pr exists
ls -la ~/.sliced-pr

# If missing, manually switch to your intended branch
git checkout your-branch-name
```

**Branch doesn't exist:**

```bash
# The saved branch might have been deleted
SAVED_BRANCH=$(cat ~/.sliced-pr)
git branch --list "$SAVED_BRANCH"

# Create the branch if it was deleted
git checkout -b "$SAVED_BRANCH"
```

**Uncommitted changes prevent checkout:**

```bash
# Stash changes before switching
git stash push -m "Temporary stash for branch switch"
dr branchCoSliced
git stash pop  # Apply stashed changes
```

#### Manual Recovery

```bash
# If branchCoSliced fails, manually restore
echo "feature/my-original-branch" > ~/.sliced-pr
dr branchCoSliced

# Or directly checkout without using the command
git checkout "$(cat ~/.sliced-pr)"
```

### Related Commands

- **branchSlice**: Creates the sliced branch and saves reference
- **branchGetSlicedCode**: Copies code from sliced branch to current working tree
- **cat ~/.sliced-pr**: Shows the currently saved branch name

### Best Practices

1. **Always check status** before slicing to ensure clean state
2. **Use descriptive branch names** for sliced branches
3. **Return promptly** after creating clean branches to avoid confusion
4. **Verify saved branch** exists before attempting to return
5. **Clean up sliced branches** periodically using branchCleanup

### Example Workflows

#### Feature Development Pattern

```bash
# Start feature
git checkout -b feature/complex-feature

# Work and experiment
# ... lots of commits, experiments, WIP ...

# Time for review - slice clean branch
dr branchSlice feature/complex-feature-v1
git add src/core-feature.js tests/
git commit -m "Add core feature functionality"
git push origin feature/complex-feature-v1

# Back to development
dr branchCoSliced

# Continue working
# ... more experiments ...

# Another review iteration
dr branchSlice feature/complex-feature-v2
git add .
git commit -m "Refactor based on feedback"
git push origin feature/complex-feature-v2

# Back to development again
dr branchCoSliced
```

### See Also

- [branchSlice.md](./branchSlice.md) - Create clean branches from current changes
- [branchGetSlicedCode.md](./branchGetSlicedCode.md) - Copy sliced branch code to working tree
- [branchCleanup.md](./branchCleanup.md) - Clean up branches after development
