#!/usr/bin/env bash
### DOC
#   (2) Check out the code of the previously-saved sliced branch
### DOC
## add command: drun add branchGetSlicedCode

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"
source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg git

main() {
  local repo_root
  repo_root=$(git_repo_root)
  local start_dir=$PWD

  local saved_branch
  saved_branch=$(<~/.sliced-pr)

  cd "$repo_root"
  git checkout "$saved_branch" -- .
  git reset

  cd "$start_dir"
}
main "$@"
