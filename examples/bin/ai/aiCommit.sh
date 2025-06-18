#!/usr/bin/env bash
### DOC
# aiCommit – generate an AI-crafted commit message (and optionally push).
#
# USAGE
#   aiCommit [--no-add] [--no-push]
#
# FLAGS
#   --no-add   Do NOT run “git add -A” automatically.
#   --no-push  Skip “git push” after committing.
#
# INTERACTIVE FLOW
#   1. Generates a commit message from the staged diff with Gemini 2.0 Flash.
#   2. Shows the message and prompts:
#        Accept   → commit (+ optional push) and save to history
#        Regenerate → try again
#        Quit      → abort, nothing saved
### DOC
set -euo pipefail

# ─── constants ────────────────────────────────────────────────────────────
LLM_MODEL=gemini-2.0-flash
COMMIT_PROMPT="$HOME/.config/prompts/commit-system-prompt.txt"
HISTORY_DIR="$HOME/.config/prompts/commit-history"

# colours
reset="$(tput sgr0)"
green="$(tput setaf 10)"
yellow="$(tput setaf 3)"
red="$(tput setaf 1)"
cyan="$(tput setaf 12)"

# ─── flags ────────────────────────────────────────────────────────────────
add_all=1
auto_push=1
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-add) add_all=0 ;;
  --no-push) auto_push=0 ;;
  *)
    echo -e "${red}Unknown option: $1${reset}"
    exit 1
    ;;
  esac
  shift
done

# ─── stage changes (optional) ─────────────────────────────────────────────
if ((add_all)); then git add -A; fi
if git diff --cached --quiet; then
  echo -e "${yellow}No staged changes. Aborting.${reset}"
  exit 0
fi

# ─── dependencies ─────────────────────────────────────────────────────────
command -v llm >/dev/null || {
  echo -e "${red}llm CLI missing${reset}"
  exit 1
}

generate() {
  git diff --cached | llm -m "$LLM_MODEL" -s "$(cat "$COMMIT_PROMPT")"
}

# ─── interactive loop ────────────────────────────────────────────────────
while :; do
  clear
  commit_msg=$(generate | sed -n '1p')
  echo -e "${green}\n──────── Commit message ────────${reset}\n$commit_msg\n"
  read -r -p "$(echo -e "${cyan}Accept [a] / Regenerate [r] / Quit [q]? ${reset}")" choice
  case "${choice,,}" in
  a | "")
    git commit -m "$commit_msg"
    ((auto_push)) && git push
    # save history (10 latest)
    mkdir -p "$HISTORY_DIR"
    printf '%s\n' "$commit_msg" >"$HISTORY_DIR/$(date +%s).txt"
    ls -1tr "$HISTORY_DIR" | head -n -10 | xargs -r -I{} rm "$HISTORY_DIR/{}"
    echo -e "${green}✅  Commit created.${reset}"
    echo -e "${green}\t\t drun prDescription \"${commit_msg}\"${reset}"
    echo ""
    break
    ;;
  r) echo -e "${yellow}🔄  Regenerating...${reset}" ;;
  q)
    echo -e "${yellow}🚫  Aborted.${reset}"
    break
    ;;
  *) echo "Please respond with a / r / q." ;;
  esac
done
