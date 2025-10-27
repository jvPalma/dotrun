#!/usr/bin/env bash
### DOC
# One line description about what this script does
### DOC
#
# Long multiline description of this script
#
# Usage/Example:
#  dr {{SCRIPT_NAME}} [args]
#
# Required Tools:
#
### DOC

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors

main() {
  echo "Running {{SCRIPT_NAME}}..."
}

main "$@"
