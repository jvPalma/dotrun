#!/usr/bin/env bash
### DOC
# hello-team - A simple hello script for team collaboration
# Demonstrates how DotRun collections can share team scripts
### DOC
set -euo pipefail

main() {
  local team_name="${1:-Team}"
  echo "Hello from the $team_name DotRun collection!"
  echo "This script was imported from a shared team repository."
  echo
  echo "Available environment variables:"
  echo "  USER: ${USER:-unknown}"
  echo "  PWD: $PWD"
  echo "  DRUN_CONFIG: ${DRUN_CONFIG:-not set}"
  echo
  echo "This demonstrates how teams can share common scripts"
  echo "while keeping their personal dotfiles separate."
}

main "$@"