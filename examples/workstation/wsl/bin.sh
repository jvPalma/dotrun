#!/usr/bin/env bash
### DOC
#   List Workstations status
### DOC
## add command: drun add wsl

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/workstation.sh"

main() {
  workstationConfigs list
}

main "$@"
