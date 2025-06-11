#!/usr/bin/env bash
### DOC
# Git Branch Cleanup - Pure Bash Implementation
# Features:
# - Interactive branch selection with colors and status indicators
# - Proper merge detection
# - Branch restoration on Ctrl+C
# - Rich branch information display
### DOC
## add command: drun add branchCleanup

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Global variables for cleanup
ORIGINAL_BRANCH=""

# Cleanup function for graceful exit
cleanup_on_exit() {
  local exit_code=$?

  # Restore original branch if we're not on it
  if [[ -n "$ORIGINAL_BRANCH" ]]; then
    local current_branch
    current_branch=$(git_current_branch 2>/dev/null || echo "")

    if [[ "$current_branch" != "$ORIGINAL_BRANCH" ]] && git show-ref --verify --quiet "refs/heads/$ORIGINAL_BRANCH"; then
      echo -e "\n🔄 Restoring original branch: $ORIGINAL_BRANCH"
      git checkout "$ORIGINAL_BRANCH" >/dev/null 2>&1 || true
    fi
  fi

  exit $exit_code
}

# Set up signal handlers
trap cleanup_on_exit EXIT INT TERM

# Ensure we're in a git repository
git_repo_root >/dev/null || {
  echo "Not in a git repository. Exiting."
  exit 1
}

interactive_cleanup() {
  local cleanup_script="$DRUN_CONFIG/helpers/bash-interactive-cleanup.sh"

  if [ ! -f "$cleanup_script" ]; then
    echo "❌ Interactive cleanup script not found: $cleanup_script"
    return 1
  fi

  # Make sure it's executable
  chmod +x "$cleanup_script"

  # Run the pure bash interactive cleanup with original branch passed as argument
  "$cleanup_script" "$ORIGINAL_BRANCH"
}

main() {
  # Store original branch for restoration
  ORIGINAL_BRANCH=$(git_current_branch)

  # Get current branch and default branch
  CURRENT_BRANCH="$ORIGINAL_BRANCH"
  DEFAULT_BRANCH=$(git_default_branch)

  echo "🧹 Starting branch cleanup"
  echo "   Current branch: $CURRENT_BRANCH"
  echo "   Default branch: $DEFAULT_BRANCH"
  echo ""

  # Switch to default branch if not already there
  if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    echo "🔄 Switching to $DEFAULT_BRANCH"
    git checkout "$DEFAULT_BRANCH"
  fi

  # Pull latest changes (with error handling)
  echo "📥 Pulling latest changes"
  if ! git fetch origin; then
    echo "⚠️  Failed to fetch from origin, continuing with local branches only"
  fi

  if ! git pull --rebase origin "$DEFAULT_BRANCH"; then
    echo "⚠️  Failed to pull/rebase, you may need to resolve conflicts manually"
    echo "    Continuing with interactive cleanup..."
  fi

  # Run interactive cleanup
  echo "🎯 Starting interactive branch cleanup..."
  interactive_cleanup

  echo "✅ Branch cleanup completed"
}

main "$@"
