#!/usr/bin/env bash
### DOC
# hello - describe what this script does
### DOC
set -euo pipefail

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#source "$SCRIPT_DIR/../helpers/myfile.sh"

main() {
  echo "Running hello..."
}

main "$@"
