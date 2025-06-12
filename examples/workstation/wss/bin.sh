#!/usr/bin/env bash
### DOC
#   Start Workstation instance - and after start, connect
### DOC
## add command: drun add wss

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/workstation.sh"

main() {
  local runningStatus
  runningStatus="$(drun wsl)"

  if [[ "$runningStatus" == "RUNNING" ]]; then
    echo "Workstation is already running."
    exit 0
  else
    workstationConfigs start
  fi

}

main "$@"
