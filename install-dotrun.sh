#!/usr/bin/env bash
set -euo pipefail

PREFIX="${DOTRUN_PREFIX:-$HOME/.dotrun}"
BIN_DIR="$PREFIX/bin"
HELPERS_DIR="$PREFIX/helpers"
COMPLETION="$PREFIX/drun_completion"
WRAPPER="$BIN_DIR/drun"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$BIN_DIR" "$HELPERS_DIR"

# 👉  Create/refresh the symlink
ln -sf "$REPO_DIR/drun" "$BIN_DIR/drun"
chmod +x "$REPO_DIR/drun"

echo "✅ Linked drun executable → $BIN_DIR/drun"

# Install helpers folder with placeholder
cat > "$HELPERS_DIR/placeholder.sh" <<'EOP'
#!/usr/bin/env bash
# Placeholder helper file for drun helpers

my_helper_function() {
  echo "This is a helper function."
}
EOP

chmod +x "$HELPERS_DIR/placeholder.sh"

# Install autocomplete script
cat > "$COMPLETION" <<'EOC'
_drun_autocomplete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="list new add edit edit:docs help"
  local BIN_DIR="${dotrun_PREFIX:-$HOME/.dotrun}/bin"
  local scripts
  IFS=$'\n' scripts=($(find "$BIN_DIR" -type f -name "*.sh" -printf "%P\n" | sed 's/\.sh$//'))

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$commands ${scripts[*]}" -- "$cur") )
  elif [[ $COMP_CWORD -eq 2 && "$prev" =~ ^(edit|edit:docs|add|help|new)$ ]]; then
    COMPREPLY=( $(compgen -W "${scripts[*]}" -- "$cur") )
  fi

  return 0
}

complete -F _drun_autocomplete drun
EOC

# Add to PATH if needed
RC="${SHELL##*/}"
case "$RC" in
  bash) STARTUP="$HOME/.bashrc" ;;
  zsh)  STARTUP="$HOME/.zshrc"  ;;
  fish) STARTUP="$HOME/.config/fish/config.fish" ;;
  *)    STARTUP="$HOME/.profile" ;;
esac

grep -q '.dotrun/bin' "$STARTUP" 2>/dev/null || {
  echo 'export PATH="$HOME/.dotrun/bin:$PATH"' >> "$STARTUP"
  echo "🔧 Added \$HOME/.dotrun/bin to PATH in $STARTUP"
}

echo "source $COMPLETION" >> "$STARTUP"

echo -e "\n✅ drun script manager installed in $PREFIX"
echo "📂 Helpers folder created at $HELPERS_DIR"
echo "📝 Autocomplete file at $COMPLETION"
echo "🔄 Reload your shell with:"
echo "    source $STARTUP"
echo "or to enable autocomplete in this session now, run:"
echo "    source $COMPLETION"
echo
echo "👉 Try:  drun new hello   &&   drun hello"