#!/usr/bin/env bash
# helpers/validation/lint.sh  – generic lint helpers for dr scripts

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

run_shell_lint() {
  local file="$1"

  if command -v shellcheck >/dev/null 2>&1; then
    echo -e "🔍  shellcheck \"$file\""
    shellcheck -e SC1091,SC2016 "$file" || true
  else
    echo "ShellCheck not found - install it via your package manager."
  fi
}
