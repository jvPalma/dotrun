#!/usr/bin/env bash
# Help message for: collection import resource selection menu

BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

cat >&2 <<EOF
${RESET}
Import resources:
  [${CYAN}a${RESET}] ${CYAN}All resources${RESET}
  [${GREEN}s${RESET}] ${GREEN}Scripts${RESET} only
  [${PURPLE}l${RESET}] ${PURPLE}Aliases${RESET} only
  [${BLUE}h${RESET}] ${BLUE}Helpers${RESET} only
  [${RED}c${RESET}] ${RED}Configs${RESET} only
  [${YELLOW}n${RESET}] ${YELLOW}None${RESET} (skip import)

EOF
