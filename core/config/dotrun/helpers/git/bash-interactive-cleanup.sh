#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154
set -euo pipefail

source "$DR_CONFIG/helpers/git/constants.sh"
source "$DR_CONFIG/helpers/git/git.sh"
source "$DR_CONFIG/helpers/global/colors.sh"

# Global variables for cleanup
ORIGINAL_BRANCH=""
TEMP_FILES=()
STASH_CREATED=false

LOCAL_ICON="💻 "
REMOTE_ICON="🌐 "
ABSENT_ICON="⬛ "
# Branch status symbols
MERGED_ICON="	✅ "
SQUASH_MERGED_ICON="	📦 "
AHEAD_ICON="	⬆️ "
BEHIND_ICON="	⬇️ "
DIVERGED_ICON="	🔀 "
UNTRACKED_ICON="	🆕 "
CURRENT_ICON="	👉 "

# Set up signal handlers
trap cleanup_on_exit EXIT INT TERM

# Ensure we're in a git repository
git_repo_root >/dev/null || {
  echo "Not in a git repository. Exiting."
  exit 1
}

main() {
  # Accept original branch as parameter, fallback to current branch detection
  if [[ $# -gt 0 && -n "$1" ]]; then
    ORIGINAL_BRANCH="$1"
  else
    ORIGINAL_BRANCH=$(git_current_branch)
  fi

  local default_branch
  default_branch=$(git_default_branch)

  echo -e "${BLUE}🧹 Starting branch cleanup${NC}"
  echo -e "   Current branch: $ORIGINAL_BRANCH"
  echo -e "   Default branch: $default_branch"
  echo ""

  # Check for uncommitted changes and stash them if needed
  check_and_stash_changes

  # Create temp files
  local branches_info_file
  local selected_file
  branches_info_file=$(create_temp_file)
  selected_file=$(create_temp_file)

  # Collect branch information
  echo -e "${GRAY}🔍 Analyzing branches...${NC}"

  while read -r branch_line; do
    if [[ -n "$branch_line" ]]; then
      local branch_info
      branch_info=$(get_branch_info "$branch_line" "$default_branch" "$ORIGINAL_BRANCH")
      if [[ -n "$branch_info" ]]; then
        echo "$branch_info" >>"$branches_info_file"
      fi
    fi
  done < <(git branch -vv)

  # Sort by merge status and date
  sort -t'|' -k7,7r -k8,8r "$branches_info_file" -o "$branches_info_file"

  # Interactive selection
  if ! interactive_branch_selection "$branches_info_file" "$selected_file"; then
    return 1
  fi

  # Show summary and confirm
  if ! show_deletion_summary "$branches_info_file" "$selected_file"; then
    return 1
  fi

  # Delete selected branches
  delete_branches "$selected_file"

  # Prune remote tracking branches
  echo -e "\n${GRAY}🌿 Pruning remote tracking branches${NC}"
  git remote prune origin

  echo -e "${GREEN}✅ Branch cleanup completed${NC}"
}

main "$@"
