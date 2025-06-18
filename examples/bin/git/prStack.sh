#!/usr/bin/env bash
### DOC
#   PR Stack Management Tool
#
#   Commands:
#     prStack init <new-branch>    - Initialize a new PR stack from default branch
#     prStack next <next-branch>   - Create next branch in the stack
#     prStack update              - Update stack after merged branches
#     prStack final               - Finalize the stack and clean up
### DOC

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"
source "$DRUN_CONFIG/helpers/pkg.sh"
source "$DRUN_CONFIG/helpers/prStack.sh"

validatePkg git

# Wrapper function for prStack_update that handles strict error mode
prStack_update_wrapper() {
  # Temporarily disable strict error handling for interactive commands
  set +e
  prStack_update
  local exit_code=$?
  set -e
  return $exit_code
}

usage() {
  cat <<EOF
Usage: prStack <command> [args]

Commands:
  init <new-branch>    Initialize a new PR stack from default branch
  next <next-branch>   Create next branch in the stack
  update              Update stack after merged branches
  final               Finalize the stack and clean up

Examples:
  prStack init feature-part1
  prStack next feature-part2
  prStack next feature-part3
  prStack update
  prStack final
EOF
}

main() {
  [[ $# -lt 1 ]] && {
    usage
    exit 1
  }

  local command="$1"
  shift

  case "$command" in
  init)
    [[ $# -lt 1 ]] && {
      echo "Error: 'init' requires a branch name"
      echo "Usage: prStack init <new-branch>"
      exit 1
    }
    prStack_init "$1"
    ;;
  next)
    [[ $# -lt 1 ]] && {
      echo "Error: 'next' requires a branch name"
      echo "Usage: prStack next <next-branch>"
      exit 1
    }
    prStack_next "$1"
    ;;
  final)
    prStack_final
    ;;
  update)
    prStack_update_wrapper
    ;;
  *)
    echo "Error: Unknown command '$command'"
    echo
    usage
    exit 1
    ;;
  esac
}

main "$@"
