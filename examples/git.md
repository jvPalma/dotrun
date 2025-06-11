# Git Workflow Automation

Collection of Git automation scripts for common development workflows.

## Branch Cleanup

Clean up merged branches and organize repository.

```bash
#!/usr/bin/env bash
### DOC
# Clean up merged branches and prune remotes
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Ensure we're in a git repository
git_repo_root > /dev/null

# Get current branch and default branch
CURRENT_BRANCH=$(git_current_branch)
DEFAULT_BRANCH=$(git_default_branch)

echo "🧹 Starting branch cleanup"
echo "   Current branch: $CURRENT_BRANCH"
echo "   Default branch: $DEFAULT_BRANCH"

# Switch to default branch if not already there
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    echo "🔄 Switching to $DEFAULT_BRANCH"
    git checkout "$DEFAULT_BRANCH"
fi

# Pull latest changes
echo "📥 Pulling latest changes"
git pull --rebase origin "$DEFAULT_BRANCH"

# Find merged branches
echo "🔍 Finding merged branches"
MERGED_BRANCHES=$(git branch --merged | grep -v "^\*" | grep -v "$DEFAULT_BRANCH" | grep -v "main\|master\|develop" || true)

if [ -n "$MERGED_BRANCHES" ]; then
    echo "📋 Merged branches to delete:"
    echo "$MERGED_BRANCHES"

    read -p "Delete these branches? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$MERGED_BRANCHES" | xargs -n 1 git branch -d
        echo "✅ Deleted merged branches"
    else
        echo "⏭️  Skipped branch deletion"
    fi
else
    echo "✨ No merged branches to clean up"
fi

# Prune remote tracking branches
echo "🌿 Pruning remote tracking branches"
git remote prune origin

# Show remaining branches
echo "📊 Remaining branches:"
git branch -v

echo "✅ Branch cleanup completed"
```

**Usage:** `drun add git/cleanup && drun git/cleanup`

---

## Commit and Push Workflow

Automated commit workflow with formatting and validation.

```bash
#!/usr/bin/env bash
### DOC
# Format, commit, and push changes with validation
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Configuration
COMMIT_MSG="${1:-}"
SKIP_HOOKS="${2:-false}"

# Ensure we're in a git repository
git_repo_root > /dev/null

echo "🚀 Starting commit workflow"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "📝 Found uncommitted changes"
else
    echo "✨ No changes to commit"
    exit 0
fi

# Stage all changes
echo "📋 Staging all changes"
git add -A

# Show what will be committed
echo "📊 Changes to be committed:"
git diff --cached --stat

# Generate commit message if not provided
if [ -z "$COMMIT_MSG" ]; then
    echo "💭 Generating commit message..."

    # Try to generate smart commit message based on changes
    CHANGED_FILES=$(git diff --cached --name-only | wc -l)
    CHANGED_TYPES=$(git diff --cached --name-only | sed 's/.*\.//' | sort | uniq | tr '\n' ' ')

    if [ "$CHANGED_FILES" -eq 1 ]; then
        SINGLE_FILE=$(git diff --cached --name-only)
        COMMIT_MSG="Update $(basename "$SINGLE_FILE")"
    else
        COMMIT_MSG="Update $CHANGED_FILES files ($CHANGED_TYPES)"
    fi

    echo "   Suggested: $COMMIT_MSG"
    read -p "Use this message? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Enter commit message:"
        read -r COMMIT_MSG
    fi
fi

# Commit with message
echo "💾 Committing: $COMMIT_MSG"
if [ "$SKIP_HOOKS" = "true" ]; then
    git commit -m "$COMMIT_MSG" --no-verify
else
    git commit -m "$COMMIT_MSG"
fi

# Push to remote
CURRENT_BRANCH=$(git_current_branch)
echo "📤 Pushing to origin/$CURRENT_BRANCH"

if git push --force-with-lease; then
    echo "✅ Successfully pushed changes"
else
    echo "❌ Push failed - you may need to pull first"
    exit 1
fi

echo "🎉 Commit workflow completed!"
```

**Usage:** `drun add git/commit && drun git/commit "Your message"`

---

## Pull Request Preparation

Prepare branch for pull request with rebasing and validation.

```bash
#!/usr/bin/env bash
### DOC
# Prepare branch for pull request with rebase and validation
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Get repository information
CURRENT_BRANCH=$(git_current_branch)
DEFAULT_BRANCH=$(git_default_branch)
REPO_ROOT=$(git_repo_root)

echo "🔧 Preparing PR for branch: $CURRENT_BRANCH"

# Stash any uncommitted changes
STASHED=false
if ! git diff-index --quiet HEAD --; then
    echo "💾 Stashing uncommitted changes"
    git stash push -m "Temporary stash for PR preparation"
    STASHED=true
fi

# Fetch latest changes
echo "📥 Fetching latest changes"
git fetch origin

# Switch to default branch and pull
echo "🔄 Updating $DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
git pull --rebase origin "$DEFAULT_BRANCH"

# Switch back to feature branch
echo "🔄 Switching back to $CURRENT_BRANCH"
git checkout "$CURRENT_BRANCH"

# Rebase onto latest default branch
echo "🔄 Rebasing onto latest $DEFAULT_BRANCH"
if git rebase "$DEFAULT_BRANCH"; then
    echo "✅ Rebase successful"
else
    echo "❌ Rebase conflicts detected"
    echo "Please resolve conflicts and run: git rebase --continue"
    exit 1
fi

# Check for package.json changes (if applicable)
if [ -f "$REPO_ROOT/package.json" ]; then
    if git diff "$DEFAULT_BRANCH"..HEAD --name-only | grep -q "package.json\|yarn.lock\|package-lock.json"; then
        echo "📦 Package dependencies changed - consider running install"
    fi
fi

# Force push the rebased branch
echo "📤 Force pushing rebased branch"
git push --force-with-lease origin "$CURRENT_BRANCH"

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    echo "🔄 Restoring stashed changes"
    git stash pop
fi

# Generate diff for review
DIFF_FILE="$REPO_ROOT/pr-diff.patch"
echo "📄 Generating diff file: $DIFF_FILE"
git diff "$DEFAULT_BRANCH"..HEAD > "$DIFF_FILE"

echo "✅ PR preparation completed!"
echo "📋 Summary:"
echo "   • Branch rebased onto latest $DEFAULT_BRANCH"
echo "   • Changes force-pushed to origin"
echo "   • Diff saved to pr-diff.patch"
echo ""
echo "🚀 Ready to create pull request!"
```

**Usage:** `drun add git/pr-prep && drun git/pr-prep`

---

## Repository Health Check

Check repository health and suggest improvements.

```bash
#!/usr/bin/env bash
### DOC
# Comprehensive repository health check
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Ensure we're in a git repository
REPO_ROOT=$(git_repo_root)
cd "$REPO_ROOT"

echo "🏥 Repository Health Check"
echo "========================="

# Basic repository info
echo "📊 Repository Information:"
echo "   Path: $REPO_ROOT"
echo "   Current branch: $(git_current_branch)"
echo "   Default branch: $(git_default_branch)"
echo "   Total commits: $(git rev-list --count HEAD)"

# Check working directory status
echo ""
echo "📋 Working Directory Status:"
if git diff-index --quiet HEAD --; then
    echo "   ✅ Working directory clean"
else
    echo "   ⚠️  Uncommitted changes present"
    git status --short | sed 's/^/   /'
fi

# Check for unpushed commits
echo ""
echo "📤 Remote Sync Status:"
UNPUSHED=$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l || echo "0")
if [ "$UNPUSHED" -eq 0 ]; then
    echo "   ✅ All commits pushed to remote"
else
    echo "   ⚠️  $UNPUSHED unpushed commits"
fi

# Check branch count
echo ""
echo "🌿 Branch Analysis:"
LOCAL_BRANCHES=$(git branch | wc -l)
REMOTE_BRANCHES=$(git branch -r | wc -l)
echo "   Local branches: $LOCAL_BRANCHES"
echo "   Remote branches: $REMOTE_BRANCHES"

# Find stale branches (no commits in 30 days)
STALE_BRANCHES=$(git for-each-ref --format='%(refname:short) %(committerdate)' refs/heads | \
    awk '$2 < "'$(date -d '30 days ago' '+%Y-%m-%d')'"' | cut -d' ' -f1 || true)

if [ -n "$STALE_BRANCHES" ]; then
    echo "   ⚠️  Stale branches (>30 days):"
    echo "$STALE_BRANCHES" | sed 's/^/     /'
fi

# Check repository size
echo ""
echo "💾 Repository Size:"
REPO_SIZE=$(du -sh .git | cut -f1)
echo "   .git directory: $REPO_SIZE"

# Check for large files
LARGE_FILES=$(find . -type f -size +10M ! -path "./.git/*" 2>/dev/null || true)
if [ -n "$LARGE_FILES" ]; then
    echo "   ⚠️  Large files (>10MB):"
    echo "$LARGE_FILES" | sed 's/^/     /'
fi

# Security checks
echo ""
echo "🔒 Security Check:"
# Check for potential secrets in recent commits
if git log --oneline -10 | grep -qi "password\|secret\|key\|token"; then
    echo "   ⚠️  Potential secrets in recent commit messages"
else
    echo "   ✅ No obvious secrets in recent commits"
fi

# Performance suggestions
echo ""
echo "🚀 Performance Suggestions:"
if [ "$LOCAL_BRANCHES" -gt 10 ]; then
    echo "   💡 Consider cleaning up old branches"
fi

if [ -n "$STALE_BRANCHES" ]; then
    echo "   💡 Remove stale branches with: git branch -d <branch>"
fi

if [ "$UNPUSHED" -gt 0 ]; then
    echo "   💡 Push commits to keep remote in sync"
fi

echo ""
echo "✅ Health check completed!"
```

**Usage:** `drun add git/health-check && drun git/health-check`
