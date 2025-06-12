#!/usr/bin/env bash
### DOC
#   One-line description of the script.
### DOC
## add command: drun add <scriptName>

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

## create or use any helper files from `$DRUN_CONFIG/helpers/`
source "$DRUN_CONFIG/helpers/myCoolHelper.sh"

main() {
  # loaded from helpers/myCoolHelper.sh
  usefullFunction

  echo "scriptName logic in this main"
}

main "$@"
