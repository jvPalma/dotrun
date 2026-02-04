#!/usr/bin/env bash
# Help message for: dr -r / dr reload

# Color codes for help output
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

cat <<EOF
${GREEN}🔄 Reloading DotRun...${RESET}

${GRAY}Note: Scripts run in subshells and cannot modify the parent shell environment.${RESET}

To reload DotRun in your ${BOLD}current shell${RESET}, run:
  ${GREEN}source ~/.drrc${RESET}

Or create a convenient alias:
  ${GREEN}alias drr='source ~/.drrc'${RESET}
EOF
