#!/usr/bin/env bash
### DOC
# prDescription – generate an AI-crafted PR title and body from the current git diff + user context.
#
# USAGE
#   prDescription [--no-save] [extra context...]
#
# EXAMPLES
#   prDescription "refactor vault creation flow"
#   prDescription --no-save
### DOC
set -euo pipefail

# Constants ────────────────────────────────────────────────────────────────
LLM_MODEL=gemini-2.0-flash
LLM_BODY_PROMPT="$HOME/.config/prompts/pr-body-prompt.txt"
LLM_TITLE_PROMPT="$HOME/.config/prompts/pr-title-prompt.txt"
USER_CONTEXT_FILE="$HOME/.config/prompts/prContext.txt"
HISTORY_DIR="$HOME/.config/prompts/pr-history"

BASE_REMOTE=origin
BASE_BRANCH=${2:-master} # Default to 'main' if not provided

# Colours
reset="$(tput sgr0)"
green="$(tput setaf 10)"
red="$(tput setaf 1)"
cyan="$(tput setaf 12)"
yellow="$(tput setaf 3)"

# ──────────────────────────────────────────────────────────────────────────
generate() {
  local context="$1"

  # Ensure llm binary exists
  command -v llm >/dev/null || {
    echo -e "${red}❌  llm CLI missing${reset}"
    exit 1
  }

  # Find merge-base with upstream
  git fetch "$BASE_REMOTE" "$BASE_BRANCH"
  local diff_base
  diff_base=$(git merge-base HEAD "$BASE_REMOTE/$BASE_BRANCH") || {
    echo -e "${yellow}⚠️  No common ancestor with $BASE_REMOTE/$BASE_BRANCH${reset}"
    exit 1
  }

  # Build prompts
  local title_template body_template prompt_title prompt_body
  title_template=$(<"$LLM_TITLE_PROMPT")
  body_template=$(<"$LLM_BODY_PROMPT")
  prompt_title="${title_template//USER_CHANGES_CONTEXT/$context}"
  prompt_body="${body_template//USER_CHANGES_CONTEXT/$context}"

  # Call LLM
  pr_title=$(git diff "$diff_base"...HEAD | llm -m "$LLM_MODEL" -s "$prompt_title")
  pr_body=$(git diff "$diff_base"...HEAD | llm -m "$LLM_MODEL" -s "$prompt_body")
}

print_result() {
  echo -e "${red}-----------------${reset}"
  echo -e "${green}------- PR Title:${reset}"
  echo -e "$pr_title"
  echo -e "${red}-----------------${reset}"
  echo -e "${green}-------- PR Body:${reset}"
  echo -e "${red}-----------------${reset}"
  echo "$pr_body" | glow - || echo "$pr_body"
  echo
}

save_history() {
  mkdir -p "$HISTORY_DIR"
  ts=$(date +%s)
  cat >"$HISTORY_DIR/$ts.txt" <<EOF
# -------------------
# PR TITLE:
# -------------------

$pr_title

# -------------------
# PR BODY CONTENT:
# -------------------
$pr_body
EOF
  # Retain only the 6 newest files
  ls -1tr "$HISTORY_DIR" | head -n -6 | xargs -r -I{} rm "$HISTORY_DIR/{}"
}

main() {
  # ─── options ────────────────────────────────────────────────────────────
  local save_history=1
  if [[ "${1:-}" == "--no-save" ]]; then
    save_history=0
    shift
  fi

  local context="$*"
  [[ -z "$context" && -f "$USER_CONTEXT_FILE" ]] && context=$(<"$USER_CONTEXT_FILE")

  # ─── interactive loop ───────────────────────────────────────────────────
  while :; do
    generate "$context"
    clear
    print_result

    read -r -p "$(echo -e "${cyan}Accept [a] / Regenerate [r] / Quit [q]? ${reset}")" choice
    case "${choice,,}" in
    a | "") # Accept (default)
      if ((save_history)); then save_history; fi
      echo -e "${green}✅  Saved. Copy & paste into your GitHub PR.${reset}"
      echo -e "${red}-----------------${reset}"
      echo -e "$pr_title"
      echo -e "${red}-----------------${reset}"
      echo "$pr_body"
      echo
      break
      ;;
    r) # Regenerate
      echo -e "${yellow}🔄  Regenerating...${reset}"
      ;;
    q) # Quit without saving
      echo -e "${yellow}🚫  Aborted (nothing saved).${reset}"
      break
      ;;
    *) # Unknown
      echo "Please respond with a / r / q."
      ;;
    esac
  done
}

main "$@"
