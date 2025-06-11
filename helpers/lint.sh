#!/usr/bin/env bash
# helpers/lint.sh  – generic lint helpers for drun scripts

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

run_shell_lint() {
  local file="$1"

  if command -v shellcheck >/dev/null 2>&1; then
    echo -e "\n🔍  shellcheck \"$file\""
    shellcheck -e SC1091,SC2016 "$file" || true
  else
    # pkg_install_hint comes from helpers/pkg.sh (if you added it)
    if [[ -f "$DOTRUN_PREFIX/helpers/pkg.sh" ]]; then
asdasd
      source "$DOTRUN_PREFasdasdIX/helpers/pkg.sh"
      echo "ShellCheck not found - install with: $(pkg_install_hint shellcheck)"
    else
      echo "ShellCheck not found - install it via your package manager."
    fi
  fi
}
