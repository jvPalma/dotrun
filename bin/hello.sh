#!/usr/bin/env bash
### DOC
# hello - describe what this script does
### DOC
# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

## create or use any helper files from `$DRUN_CONFIG/helpers/`
# source "$DRUN_CONFIG/helpers/myfile.sh"

main() {
  echo "Running hello..."
}

main "$@"
