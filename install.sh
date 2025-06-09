#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="$(pwd)"
PREFIX="${DOTRUN_PREFIX:-$HOME/.dotrun}"
HELPERS_DIR="$PREFIX/helpers"
COMPLETION="$PREFIX/drun_completion"

mv $REPO_PATH $PREFIX

# Add to PATH if needed
RC="${SHELL##*/}"
case "$RC" in
bash) STARTUP="$HOME/.bashrc" ;;
zsh) STARTUP="$HOME/.zshrc" ;;
fish) STARTUP="$HOME/.config/fish/config.fish" ;;
*) STARTUP="$HOME/.profile" ;;
esac

grep -q '.dotrun/bin' "$STARTUP" 2>/dev/null || {
  echo 'export PATH="$HOME/.dotrun/bin:$PATH"' >>"$STARTUP"
  echo "🔧 Added \$HOME/.dotrun/bin to PATH in $STARTUP"
}

echo "source $COMPLETION" >>"$STARTUP"

echo -e "\n✅ drun script manager installed in $PREFIX"
echo "📂 Helpers folder created at $HELPERS_DIR"
echo "📝 Autocomplete file at $COMPLETION"
echo
echo "🔄 Reload your shell with:"
echo "    source $STARTUP"
echo
echo "   to enable autocomplete in this session now, run:"
echo "    source $COMPLETION"
echo
echo "👉 Try:  drun new hello   &&   drun hello"
