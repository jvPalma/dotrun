#!/usr/bin/env bash
# Help message for: invalid GitHub URL format error

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
${RED}Error:${RESET} Invalid GitHub URL format

${GRAY}Valid formats:${RESET}
  ${GREEN}HTTPS:${RESET} https://github.com/user/repo
  ${GREEN}SSH:${RESET}   git@github.com:user/repo
  ${GREEN}Local:${RESET} /path/to/collection ${GRAY}(for testing)${RESET}

${GRAY}Common mistakes:${RESET}
  ${RED}✗${RESET} Missing protocol:     github.com/user/repo
  ${RED}✗${RESET} Wrong protocol:       http://github.com/user/repo
  ${RED}✗${RESET} Extra path:           https://github.com/user/repo/tree/main
  ${RED}✗${RESET} Non-GitHub URL:       https://gitlab.com/user/repo

${GRAY}Examples:${RESET}
  ${GREEN}HTTPS (public/private):${RESET} dr -col add https://github.com/jvPalma/dotrun.git
  ${GREEN}SSH (private repos):${RESET}    dr -col add git@github.com:company/private-repo.git
  ${GREEN}Local (testing):${RESET}        dr -col add /path/to/local/collection
EOF
