#!/usr/bin/env bash
### DOC
#   (1) Create new sliced branch from default branch
### DOC
## add command: drun add branchSlice

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"
source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg git

main() {
  [[ $# -lt 1 ]] && {
    echo "Usage: branchSlice <new-branch>"
    exit 1
  }
  local new_branch="$1"

  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD
  local src_branch
  src_branch=$(git_current_branch)

  echo "$src_branch" >~/.sliced-pr # remember source branch

  cd "$repo_root"
  local default_branch
  default_branch=$(git_default_branch)

  git checkout "$default_branch"
  git pull --ff-only

  git switch -C "$new_branch"     # create/reset new branch
  git checkout "$src_branch" -- . # copy changes
  git reset                       # unstage

  cd "$start_dir"
}
main "$@"
