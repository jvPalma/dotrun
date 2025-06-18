#!/usr/bin/env bash
# PR Stack helper functions

# shellcheck disable=SC2128
# shellcheck disable=SC2164
# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# State file locations (in script directory)
PRSTACK_STATE_DIR="$DRUN_CONFIG/bin/git/.prstack"
PRSTACK_INITIAL_BRANCH_FILE="$PRSTACK_STATE_DIR/initial-branch"
PRSTACK_STACK_FILE="$PRSTACK_STATE_DIR/stack-branches"

# Ensure state directory exists
_ensure_state_dir() {
  mkdir -p "$PRSTACK_STATE_DIR"
}

# Clean up all state files
_cleanup_state() {
  [[ -d "$PRSTACK_STATE_DIR" ]] && rm -rf "$PRSTACK_STATE_DIR"
}

# Save initial branch
_save_initial_branch() {
  local branch="$1"
  _ensure_state_dir
  echo "$branch" >"$PRSTACK_INITIAL_BRANCH_FILE"
}

# Get initial branch
_get_initial_branch() {
  [[ -f "$PRSTACK_INITIAL_BRANCH_FILE" ]] || {
    echo "Error: No PR stack initialized. Run 'prStack init <branch>' first." >&2
    return 1
  }
  cat "$PRSTACK_INITIAL_BRANCH_FILE"
}

# Add branch to stack
_add_to_stack() {
  local branch="$1"
  _ensure_state_dir
  echo "$branch" >>"$PRSTACK_STACK_FILE"
}

# Get all stack branches
_get_stack_branches() {
  [[ -f "$PRSTACK_STACK_FILE" ]] && cat "$PRSTACK_STACK_FILE" || true
}

# Get last branch in stack
_get_last_stack_branch() {
  [[ -f "$PRSTACK_STACK_FILE" ]] && tail -n 1 "$PRSTACK_STACK_FILE" || echo ""
}

# Remove first branch from stack
_remove_first_stack_branch() {
  [[ -f "$PRSTACK_STACK_FILE" ]] || return 1
  local temp_file="$PRSTACK_STACK_FILE.tmp"
  tail -n +2 "$PRSTACK_STACK_FILE" >"$temp_file" && mv "$temp_file" "$PRSTACK_STACK_FILE"
}

# Check if branch is merged (regular merge)
_is_branch_regular_merged() {
  local branch_name="$1"
  local default_branch="$2"

  # Count unique commits that are NOT in origin/master with explicit error handling
  local unique_commits="1" # Default to "not merged"
  if unique_commits=$(git rev-list --count "$branch_name" --not "origin/$default_branch" 2>/dev/null); then
    # A branch is considered merged if it has NO unique commits
    if [[ "$unique_commits" -eq 0 ]]; then
      return 0 # Branch is merged - all commits are already in origin/master
    fi
  fi

  return 1 # Branch is not merged - has unique commits or git command failed
}

# Check if branch is squash-merged
_is_branch_squash_merged() {
  local branch_name="$1"
  local default_branch="$2"

  # Count unique commits with explicit error handling
  local unique_commits="0" # Default value
  if ! unique_commits=$(git rev-list --count "$branch_name" --not "origin/$default_branch" 2>/dev/null); then
    return 1 # Git command failed, assume not squash-merged
  fi

  # Must have unique commits to be squash-merged
  if [[ "$unique_commits" -eq 0 ]]; then
    return 1 # No unique commits = regular merge
  fi

  # Check if remote branch is gone (strong indicator of squash-merge)
  local has_remote="false"
  if git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null; then
    has_remote="true"
  fi

  if [[ "$has_remote" == "false" ]]; then
    # Remote branch is gone - likely squash-merged
    return 0 # Remote gone = likely squash-merged
  fi

  return 1 # Not squash-merged
}

# Check if branch is merged using either method
_is_branch_merged() {
  local branch_name="$1"
  local default_branch="$2"

  if _is_branch_regular_merged "$branch_name" "$default_branch" 2>/dev/null; then
    return 0 # Branch is merged
  elif _is_branch_squash_merged "$branch_name" "$default_branch" 2>/dev/null; then
    return 0 # Branch is squash-merged
  fi

  return 1 # Branch is not merged
}

# Get branch information for display
_get_branch_display_info() {
  local branch_name="$1"
  local default_branch="$2"
  local is_current="$3"
  local prev_branch="${4:-$default_branch}" # Optional previous branch, defaults to default_branch

  # Get commit info with explicit error handling
  local last_commit_date=""
  local last_author="Unknown"

  # Use explicit error handling instead of relying on set -e
  if last_commit_date=$(git log -1 --format="%ai" "$branch_name" 2>/dev/null); then
    : # Command succeeded
  fi

  if last_author=$(git log -1 --format="%an" "$branch_name" 2>/dev/null); then
    : # Command succeeded
  fi

  # Calculate relative date
  local relative_date="unknown"
  if [[ -n "$last_commit_date" ]]; then
    local now diff_seconds diff_days
    now=$(date +%s)
    diff_seconds=$((now - $(date -d "$last_commit_date" +%s 2>/dev/null || echo "$now")))
    diff_days=$((diff_seconds / 86400))

    if [[ $diff_days -eq 0 ]]; then
      relative_date="today"
    elif [[ $diff_days -eq 1 ]]; then
      relative_date="yesterday"
    elif [[ $diff_days -lt 7 ]]; then
      relative_date="${diff_days} days ago"
    elif [[ $diff_days -lt 30 ]]; then
      relative_date="$((diff_days / 7)) weeks ago"
    else
      relative_date="$((diff_days / 30)) months ago"
    fi
  fi

  # Check remote status
  local remote_status="💻 ⬛ "
  if git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null; then
    remote_status="💻 🌐 "
  fi

  # Calculate diff counts (additions and deletions)
  local diff_vs_default_add="0" diff_vs_default_del="0"
  local diff_vs_prev_add="0" diff_vs_prev_del="0"

  # Get diff stats against default branch
  if local diff_output=$(git diff --numstat "origin/$default_branch...$branch_name" 2>/dev/null); then
    if [[ -n "$diff_output" ]]; then
      # Sum up all additions and deletions
      while IFS=$'\t' read -r additions deletions filename; do
        [[ "$additions" != "-" ]] && ((diff_vs_default_add += additions))
        [[ "$deletions" != "-" ]] && ((diff_vs_default_del += deletions))
      done <<<"$diff_output"
    fi
  fi

  # Get diff stats against previous branch (only if different from default)
  if [[ "$prev_branch" != "$default_branch" ]]; then
    if local diff_output_prev=$(git diff --numstat "$prev_branch...$branch_name" 2>/dev/null); then
      if [[ -n "$diff_output_prev" ]]; then
        # Sum up all additions and deletions
        while IFS=$'\t' read -r additions deletions filename; do
          [[ "$additions" != "-" ]] && ((diff_vs_prev_add += additions))
          [[ "$deletions" != "-" ]] && ((diff_vs_prev_del += deletions))
        done <<<"$diff_output_prev"
      fi
    fi
  fi

  # Determine status icon and color
  local icon color status_text
  if [[ "$is_current" == "true" ]]; then
    icon="👉"
    color="\033[0;36m" # Cyan
    status_text="Current branch"
  elif _is_branch_regular_merged "$branch_name" "$default_branch" 2>/dev/null; then
    icon="✅"
    color="\033[0;32m" # Green
    status_text="Merged"
  elif _is_branch_squash_merged "$branch_name" "$default_branch" 2>/dev/null; then
    icon="📦"
    color="\033[0;32m" # Green
    status_text="Squash-merged"
  else
    icon="⬆️"
    color="\033[0;34m" # Blue
    status_text="Ahead"
  fi

  # Output: icon|color|branch_name|relative_date|author|remote_status|status_text|is_merged|diff_vs_default_add|diff_vs_default_del|diff_vs_prev_add|diff_vs_prev_del
  local is_merged="false"
  if _is_branch_merged "$branch_name" "$default_branch" 2>/dev/null; then
    is_merged="true"
  fi

  echo "$icon|$color|$branch_name|$relative_date|$last_author|$remote_status|$status_text|$is_merged|$diff_vs_default_add|$diff_vs_default_del|$diff_vs_prev_add|$diff_vs_prev_del"
}

# Initialize PR stack
prStack_init() {
  local new_branch="$1"

  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD
  local src_branch
  src_branch=$(git_current_branch)

  echo "Initializing PR stack..."
  echo "Source branch: $src_branch"
  echo "New branch: $new_branch"

  # Save the initial branch
  _save_initial_branch "$src_branch"

  cd "$repo_root"
  local default_branch
  default_branch=$(git_default_branch)

  echo "Switching to default branch: $default_branch"
  git checkout "$default_branch"
  git pull --ff-only

  echo "Creating new branch: $new_branch"
  git switch -C "$new_branch"     # create/reset new branch
  git checkout "$src_branch" -- . # copy changes
  git reset                       # unstage

  # Add this branch to the stack
  _add_to_stack "$new_branch"

  cd "$start_dir"

  echo "✅ PR stack initialized!"
  echo "Current branch: $new_branch"
  echo "You can now make your changes and create a PR."
  echo "When ready for the next part, run: prStack next <next-branch-name>"
}

# Create next branch in stack
prStack_next() {
  local next_branch="$1"

  # Verify we have an initialized stack
  _get_initial_branch >/dev/null || return 1

  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD
  local current_branch
  current_branch=$(git_current_branch)

  echo "Creating next branch in PR stack..."
  echo "Current branch: $current_branch"
  echo "Next branch: $next_branch"

  # shellcheck disable=SC2164
  cd "$repo_root"

  # Create new branch from current one
  git switch -C "$next_branch"

  # Add this branch to the stack
  _add_to_stack "$next_branch"

  cd "$start_dir"

  echo "✅ Next branch created!"
  echo "Current branch: $next_branch"
  echo "This branch is based on: $current_branch"
  echo "You can continue making changes and create another PR."
  echo "When ready for the next part, run: prStack next <next-branch-name>"
  echo "When done with the entire stack, run: prStack final"
}

# Finalize the PR stack
prStack_final() {
  # Verify we have an initialized stack
  local initial_branch
  initial_branch=$(_get_initial_branch) || return 1

  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD
  local stack_branches
  stack_branches=$(_get_stack_branches)
  local last_branch
  last_branch=$(_get_last_stack_branch)

  echo "Finalizing PR stack..."
  echo "Initial branch: $initial_branch"
  echo "Stack branches:"
  echo "$stack_branches" | sed 's/^/  - /'
  echo "Last branch: $last_branch"

  cd "$repo_root"

  # Switch back to initial branch
  echo "Switching back to initial branch: $initial_branch"
  git checkout "$initial_branch"

  # If there's a last branch, rebase from it
  if [[ -n "$last_branch" ]]; then
    echo "Rebasing from last stack branch: $last_branch"
    # This will help maintain the commit history from the stack
    git rebase "$last_branch"
  fi

  cd "$start_dir"

  # Clean up state files
  echo "Cleaning up PR stack state..."
  _cleanup_state

  echo "✅ PR stack finalized!"
  echo "Current branch: $initial_branch"
  echo "All state files have been cleaned up."
}

# Update PR stack after merged branches
prStack_update() {
  # Verify we have an initialized stack
  local initial_branch
  initial_branch=$(_get_initial_branch) || return 1

  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD
  local stack_branches
  stack_branches=$(_get_stack_branches)

  [[ -z "$stack_branches" ]] && {
    echo "No stack branches found. Nothing to update."
    return 0
  }

  cd "$repo_root" || return 1

  # Get default branch for merge checking
  local default_branch
  default_branch=$(git_default_branch)

  # Get current branch
  local current_branch
  current_branch=$(git_current_branch)

  # Fetch latest changes
  echo "📥 Fetching latest changes..."
  git fetch origin || {
    echo "⚠️  Failed to fetch from origin, continuing with local state"
  }

  # Colors
  local NC='\033[0m'
  local BLUE='\033[0;34m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local GRAY='\033[0;90m'
  local PURPLE='\033[0;35m'

  while true; do
    clear
    echo -e "${BLUE}🧹 Interactive Stack Branch Rebase Update${NC}\n"

    # Display initial branch
    echo -e "${GRAY}Initial Stacked branch:${NC}"
    local initial_info
    initial_info=$(_get_branch_display_info "$initial_branch" "$default_branch" "false")
    IFS='|' read -r icon color branch_name relative_date author remote_status status_text is_merged diff_vs_default_add diff_vs_default_del diff_vs_prev_add diff_vs_prev_del <<<"$initial_info"

    # Format diff display for initial branch
    local initial_diff_display=""
    if [[ "$diff_vs_default_add" -gt 0 || "$diff_vs_default_del" -gt 0 ]]; then
      initial_diff_display="${GRAY}(+${diff_vs_default_add} −${diff_vs_default_del})${NC}"
    fi

    echo -e "   🟣  ${PURPLE}${branch_name}${NC} ${initial_diff_display}"
    echo -e "        ${GRAY}${relative_date} • ${author} • (${remote_status})${NC}"
    echo

    # Display stacked branches
    echo -e "${GRAY}Stacked branches:${NC}"
    echo

    local merged_count=0
    local branch_count=0
    local merged_branches=()
    local prev_branch="$initial_branch" # Start with initial branch as previous

    while IFS= read -r branch; do
      [[ -z "$branch" ]] && continue
      ((branch_count++))

      local is_current_branch="false"
      [[ "$branch" == "$current_branch" ]] && is_current_branch="true"

      local branch_info
      branch_info=$(_get_branch_display_info "$branch" "$default_branch" "$is_current_branch" "$prev_branch")
      IFS='|' read -r icon color branch_name relative_date author remote_status status_text is_merged diff_vs_default_add diff_vs_default_del diff_vs_prev_add diff_vs_prev_del <<<"$branch_info"

      # Format diff display: [+X −Y from previous, +A −B from master]
      local diff_display=""
      if [[ "$prev_branch" != "$default_branch" ]]; then
        local prev_part=""
        local default_part=""

        # Format previous branch diff
        if [[ "$diff_vs_prev_add" -gt 0 || "$diff_vs_prev_del" -gt 0 ]]; then
          prev_part="+${diff_vs_prev_add} −${diff_vs_prev_del}"
        else
          prev_part="no changes"
        fi

        # Format default branch diff
        if [[ "$diff_vs_default_add" -gt 0 || "$diff_vs_default_del" -gt 0 ]]; then
          default_part="+${diff_vs_default_add} −${diff_vs_default_del}"
        else
          default_part="no changes"
        fi

        diff_display="${GRAY}[${prev_part}, ${default_part}]${NC}"
      else
        # Just show diff vs default branch
        if [[ "$diff_vs_default_add" -gt 0 || "$diff_vs_default_del" -gt 0 ]]; then
          diff_display="${GRAY}[+${diff_vs_default_add} −${diff_vs_default_del}]${NC}"
        fi
      fi

      if [[ "$is_merged" == "true" ]]; then
        ((merged_count++))
        merged_branches+=("$branch")
        echo -e "${branch_count}) 🔵   ${icon} ${color}${branch_name}${NC} ${diff_display} ${status_text}"
      else
        echo -e "${branch_count}) ⚫   ${icon} ${color}${branch_name}${NC} ${diff_display}"
      fi
      echo -e "            ${GRAY}${relative_date} • ${author} • (${remote_status})${NC}"

      # Update prev_branch for next iteration
      prev_branch="$branch"
    done <<<"$stack_branches"

    echo

    # Show status based on merged branches
    if [[ $merged_count -eq 0 ]]; then
      echo -e "${GRAY}No updates available for now${NC}"
      echo
      echo -e "${YELLOW}Options:${NC}"
      echo "  [r] Refresh status"
      echo "  [q] Quit"
      echo
      read -p "Choice [q]: " -r choice
      choice=${choice:-q}

      case $choice in
      r | R) continue ;;
      q | Q) break ;;
      *)
        echo -e "${YELLOW}Invalid choice. Try again.${NC}"
        sleep 1
        ;;
      esac
    else
      echo -e "${GREEN}Stacked branch(es) merged detected:${NC}"
      echo -e "${GRAY}  Total: $merged_count branch(es)${NC}"
      echo
      echo -e "${YELLOW}Options:${NC}"
      echo "  [1] Rebase original branch with the first merged stacked branch"
      echo "  [2] Cascade rebase all stacked branches"
      echo "  [A] Rebase all stacked branches and initial branch"
      echo "  [q] Quit"
      echo
      read -p "Choice [A]: " -r choice
      choice=${choice:-A}

      case $choice in
      1)
        _rebase_initial_branch "$initial_branch" "${merged_branches[0]}"
        break
        ;;
      2)
        _cascade_rebase_stacked_branches "$stack_branches" "$merged_branches"
        break
        ;;
      A | a)
        _rebase_all_branches "$initial_branch" "$stack_branches" "$merged_branches"
        break
        ;;
      q | Q)
        break
        ;;
      *)
        echo -e "${YELLOW}Invalid choice. Try again.${NC}"
        sleep 1
        ;;
      esac
    fi
  done

  cd "$start_dir" || return 1
}

# Rebase just the initial branch
_rebase_initial_branch() {
  local initial_branch="$1"
  local merged_branch="$2"

  echo "📦 Rebasing initial branch: $initial_branch from $merged_branch"
  git checkout "$initial_branch" || {
    echo "❌ Failed to checkout initial branch: $initial_branch"
    return 1
  }

  git rebase "origin/$merged_branch" || {
    echo "❌ Failed to rebase $initial_branch from origin/$merged_branch"
    return 1
  }

  git push --force-with-lease || {
    echo "⚠️  Failed to push $initial_branch"
  }

  echo "✅ Initial branch rebased successfully!"
}

# Cascade rebase stacked branches only
_cascade_rebase_stacked_branches() {
  local stack_branches="$1"
  local merged_branches=("${@:2}")

  echo "🔄 Starting cascade rebase of stacked branches..."

  local prev_branch="${merged_branches[0]}"
  while IFS= read -r current_branch; do
    [[ -z "$current_branch" ]] && continue

    # Skip if this is a merged branch
    local is_merged=false
    for merged in "${merged_branches[@]}"; do
      if [[ "$current_branch" == "$merged" ]]; then
        is_merged=true
        prev_branch="$current_branch"
        break
      fi
    done

    [[ "$is_merged" == "true" ]] && continue

    echo "📦 Rebasing branch: $current_branch from $prev_branch"
    git checkout "$current_branch" || {
      echo "❌ Failed to checkout branch: $current_branch"
      continue
    }

    git rebase "origin/$prev_branch" || {
      echo "❌ Failed to rebase $current_branch from origin/$prev_branch"
      continue
    }

    git push --force-with-lease || {
      echo "⚠️  Failed to push $current_branch"
    }

    prev_branch="$current_branch"
  done <<<"$stack_branches"

  # Remove merged branches from stack
  for merged in "${merged_branches[@]}"; do
    echo "🧹 Removing merged branch from stack: $merged"
    _remove_first_stack_branch
  done

  echo "✅ Cascade rebase completed!"
}

# Rebase all branches (initial + stacked)
_rebase_all_branches() {
  local initial_branch="$1"
  local stack_branches="$2"
  local merged_branches=("${@:3}")

  echo "🔄 Starting full rebase (initial + stacked branches)..."

  # First rebase initial branch
  _rebase_initial_branch "$initial_branch" "${merged_branches[0]}"

  # Then cascade rebase stacked branches
  _cascade_rebase_stacked_branches "$stack_branches" "${merged_branches[@]}"

  echo "✅ Full rebase completed!"
}
