#!/usr/bin/env bash
### DOC
#   (3) Checkout into initial Sliced Branch
### DOC

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DR_CONFIG/helpers/git.sh"
source "$DR_CONFIG/helpers/pkg.sh"

validatePkg git

main() {
  local branchToReturn
  branchToReturn=$(cat ~/.sliced-pr)
  git checkout "$branchToReturn"
}

main "$@"
