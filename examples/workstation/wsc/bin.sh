#!/usr/bin/env bash
### DOC
#   SSH into Workstation
### DOC
## add command: drun add wsc

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/workstation.sh"

main() {
  local runningStatus
  runningStatus="$(drun wsl)"

  if [[ "$runningStatus" == "RUNNING" ]]; then
    workstationConfigs ssh -- -t fish
  else
    echo "Workstation is not running. Starting it now..."
    workstationConfigs start
    workstationConfigs ssh -- -t fish
  fi
}

main "$@"
