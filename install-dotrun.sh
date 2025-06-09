#!/usr/bin/env bash
set -euo pipefail

PREFIX="${dotrun_PREFIX:-$HOME/.dotrun}"
BIN_DIR="$PREFIX/bin"
HELPERS_DIR="$PREFIX/helpers"
COMPLETION="$PREFIX/drun_completion"
WRAPPER="$BIN_DIR/drun"

mkdir -p "$BIN_DIR" "$HELPERS_DIR"

# Install main drun script
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash

# drun — micro script manager
dotrun_PREFIX="${dotrun_PREFIX:-$HOME/.dotrun}"
BIN_DIR="$dotrun_PREFIX/bin"
DOC_TOKEN="### DOC"
EDITOR="${EDITOR:-nano}"
color_script="\033[1;92m"  # Bright Green
color_doc="\033[0;37m"     # Gray
color_reset="\033[0m"

mkdir -p "$BIN_DIR"

list_scripts() {
  find "$BIN_DIR" -type f -name "*.sh" | sort | while read -r file; do
    rel_path="${file#$BIN_DIR/}"
    script_name="$(basename "$rel_path" .sh)"
    IFS='/' read -ra PARTS <<< "$rel_path"
    indent=""
    for i in "${!PARTS[@]}"; do
      part="${PARTS[$i]}"
      is_last=$((i == ${#PARTS[@]} - 1))
      if [[ "$part" == *.sh ]]; then
        echo -e "${indent}${color_script}${script_name}${color_reset}"
        awk "/^$DOC_TOKEN/ { show = !show; next } show { print \"$indent  ${color_doc}\" \$0 \"$color_reset\" }" "$file"
      else
        echo -e "${indent}\033[1;33m📂 $part${color_reset}"
        indent="  $indent"
      fi
    done
  done
}

create_script_skeleton() {
  local name="$1"
  local file="$BIN_DIR/$name.sh"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<EOSC
#!/usr/bin/env bash
$DOC_TOKEN
# $(basename "$name") - describe what this script does
$DOC_TOKEN
set -euo pipefail

#SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
#source "\$SCRIPT_DIR/../helpers/myfile.sh"

main() {
  echo "Running $(basename "$name")..."
}

main "\$@"
EOSC
  chmod +x "$file"
}

find_script_file() {
  local name="$1"
  find "$BIN_DIR" -type f -name "$(basename "$name").sh" | head -n 1
}

new_script() {
  local name="$1"
  local file="$BIN_DIR/$name.sh"
  if [[ -e "$file" ]]; then
    echo "Script '$name' already exists at $file"
    exit 1
  fi
  create_script_skeleton "$name"
  echo "Created new script: $file"
}

add_script() {
  local name="$1"
  local file="$BIN_DIR/$name.sh"
  if [[ ! -f "$file" ]]; then
    create_script_skeleton "$name"
    echo "Created new script: $file"
  fi
  "$EDITOR" "$file"
}

edit_script() {
  local file
  file=$(find_script_file "$1")
  if [[ -n "$file" ]]; then
    "$EDITOR" "$file"
  else
    echo "Script '$1' not found"
    exit 1
  fi
}

edit_docs() {
  local file
  file=$(find_script_file "$1")
  if [[ -n "$file" ]]; then
    "$EDITOR" "$file"
  else
    echo "Script '$1' not found"
    exit 1
  fi
}

show_help() {
  local file
  file=$(find_script_file "$1")
  if [[ -z "$file" ]]; then
    echo "Script '$1' not found"
    exit 1
  fi
  awk "/^$DOC_TOKEN/ { p = !p; next } p" "$file"
}

run_script() {
  local name="$1"
  shift
  local file
  file=$(find_script_file "$name")
  if [[ -z "$file" ]]; then
    echo "Script '$name' not found"
    exit 1
  fi
  "$file" "$@"
}

case "$1" in
  list)
    list_scripts
    ;;
  new)
    [[ -z "$2" ]] && { echo "Usage: drun new <name>"; exit 1; }
    new_script "$2"
    ;;
  add)
    [[ -z "$2" ]] && { echo "Usage: drun add <name>"; exit 1; }
    add_script "$2"
    ;;
  edit)
    [[ -z "$2" ]] && { echo "Usage: drun edit <name>"; exit 1; }
    edit_script "$2"
    ;;
  edit:docs)
    [[ -z "$2" ]] && { echo "Usage: drun edit:docs <name>"; exit 1; }
    edit_docs "$2"
    ;;
  help)
    [[ -z "$2" ]] && { echo "Usage: drun help <name>"; exit 1; }
    show_help "$2"
    ;;
  "" | -h | --help)
    echo "drun <command> [args...]"
    echo
    echo "Commands"
    echo "  list                List all managed scripts in tree format"
    echo "  new <name>          Create <name>.sh skeleton in \$BIN_DIR"
    echo "  add <name>          Create and open <name>.sh in editor"
    echo "  edit <name>         Open existing script in editor"
    echo "  edit:docs <name>    Open script at docs section"
    echo "  help <name>         Show embedded docs for <name>"
    echo "  <name> [args…]      Execute script <name> from anywhere"
    echo
    echo "Env"
    echo "  dotrun_PREFIX    Override root (default \$HOME/.dotrun)"
    echo "  EDITOR              Command to open editor (default: nano)"
    exit 0
    ;;
  *)
    if [[ -n "$1" ]]; then
      run_script "$@"
    else
      echo "Unknown command: $1"
      exit 1
    fi
    ;;
esac
EOF

chmod +x "$WRAPPER"

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