#!/usr/bin/env bash
### DOC
#   Stop Workstation instance
### DOC
## add command: drun add wstp

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/workstation.sh"

main() {

  local runningStatus
  runningStatus="$(drun wsl)"

  if [[ "$runningStatus" == "RUNNING" ]]; then
    workstationConfigs stop
  else
    echo "Workstation is not running."
    exit 0
  fi

}

main "$@"
