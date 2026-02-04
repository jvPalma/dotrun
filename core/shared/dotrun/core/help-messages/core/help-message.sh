#!/usr/bin/env bash
# Help message for: dr --help / dr -h / dr (no args)

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

${BOLD}${CYAN}dr${RESET} ${GRAY}<command> [args...]${RESET}

${BOLD}Core Commands${RESET}
  ${CYAN}-l${RESET}                  List all scripts ${GRAY}(names only)${RESET}
  ${CYAN}-L${RESET}                  List scripts with docs, optionally scoped
  ${CYAN}-l/L${RESET} ${YELLOW}[folder/]${RESET}      List scripts within the scoped folder
  ${CYAN}-r/reload${RESET}           Reload full DotRun tool features

${BOLD}${GREEN}Script Management${RESET} ${GRAY}(${GREEN}-s${RESET}${GRAY} or ${GREEN}scripts${RESET}${GRAY}, or ${GREEN}nothing${RESET}${GRAY} - the \`Script\` feature is default behavior)${RESET}
  ${GREEN}set${RESET} ${YELLOW}<name>${RESET}       Create or open ${YELLOW}<name>${RESET}.sh in editor ${GRAY}(idempotent)${RESET}
  ${GREEN}move${RESET} ${YELLOW}<src> <dst>${RESET} Move/rename script
  ${GREEN}rm${RESET} ${YELLOW}<name>${RESET}        Remove script
  ${GREEN}help${RESET} ${YELLOW}<name>${RESET}      Show inline docs
  ${GREEN}${YELLOW}<name>${RESET} ${GRAY}[args…]${RESET}   Execute script ${YELLOW}<name>${RESET} from anywhere

${BOLD}${PURPLE}Aliases Management${RESET} ${GRAY}(${PURPLE}-a${RESET}${GRAY} or ${PURPLE}aliases${RESET}${GRAY})${RESET}
  ${PURPLE}-a${RESET} ${YELLOW}<path/to/file>${RESET}        Create or edit alias file ${GRAY}(default action)${RESET}
  ${PURPLE}-a -l${RESET} ${YELLOW}[folder/]${RESET}         List aliases in tree view ${GRAY}(short)${RESET}
  ${PURPLE}-a -L${RESET} ${YELLOW}[folder/]${RESET}         List aliases in tree view ${GRAY}(with descriptions)${RESET}
  ${PURPLE}-a move${RESET} ${YELLOW}<src> <dst>${RESET}     Move/rename alias file
  ${PURPLE}-a rm${RESET} ${YELLOW}<file>${RESET}            Remove alias file
  ${PURPLE}-a help${RESET} ${YELLOW}<file>${RESET}          Show alias documentation
  ${PURPLE}-a init${RESET}               Initialize aliases folder

${BOLD}${RED}Configuration Management${RESET} ${GRAY}(${RED}-c${RESET}${GRAY} or ${RED}config${RESET}${GRAY})${RESET}
  ${RED}-c${RESET} ${YELLOW}<path/to/file>${RESET}        Create or edit config file ${GRAY}(default action)${RESET}
  ${RED}-c -l${RESET} ${YELLOW}[folder/]${RESET}         List configs in tree view ${GRAY}(short)${RESET}
  ${RED}-c -L${RESET} ${YELLOW}[folder/]${RESET}         List configs in tree view ${GRAY}(with descriptions)${RESET}
  ${RED}-c move${RESET} ${YELLOW}<src> <dst>${RESET}     Move/rename config file
  ${RED}-c rm${RESET} ${YELLOW}<file>${RESET}            Remove config file
  ${RED}-c help${RESET} ${YELLOW}<file>${RESET}          Show config documentation
  ${RED}-c init${RESET}               Initialize configs folder

${BOLD}${BLUE}Collections System${RESET} ${GRAY}(${BLUE}-col${RESET}${GRAY} or ${BLUE}collections${RESET}${GRAY})${RESET}
  ${GRAY}Share and update script collections from Git repositories with version tracking,${RESET}
  ${GRAY}conflict resolution, and modification detection via SHA256 hashes.${RESET}

  ${BLUE}-col${RESET}                Interactive collection browser ${GRAY}(browse and import resources)${RESET}
  ${BLUE}-col init${RESET}           Initialize collection structure ${GRAY}(for authors creating collections)${RESET}
  ${BLUE}-col add${RESET} ${YELLOW}<url>${RESET}      Install collection from GitHub ${GRAY}(clone, import resources, track version)${RESET}
  ${BLUE}-col list${RESET}           List installed collections with versions and imported resources
  ${BLUE}-col sync${RESET}           Check all collections for available updates ${GRAY}(fetch latest tags)${RESET}
  ${BLUE}-col update${RESET} ${YELLOW}[name]${RESET}  Update collection ${GRAY}(interactive selection if no name given)${RESET}
  ${BLUE}-col remove${RESET} ${YELLOW}<name>${RESET}  Remove collection tracking ${GRAY}(keeps imported files)${RESET}
  ${BLUE}-col --help${RESET}         Show detailed collections help with workflows and examples

${BOLD}Environment Variables${RESET}
  ${YELLOW}EDITOR${RESET}            Command to open editor ${GRAY}(default: auto-detect)${RESET}
EOF
