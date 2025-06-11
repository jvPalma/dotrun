#!/usr/bin/env bash
### DOC
#   (3) Checkout into initial Sliced Branch
### DOC
## add command: drun add branchCoSliced

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"
source "$DRUN_CONFIG/helpers/pkg.sh"

validatePkg git

main() {
  local branchToReturn
  branchToReturn=$(cat ~/.sliced-pr)
  git checkout "$branchToReturn"
}

main "$@"
