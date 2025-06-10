#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# 0.  Variables (define first!)
# ------------------------------------------------------------------
SRC_DIR="$(pwd)"                                   # <─ now defined early
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotrun"
BIN_DEST="/usr/local/bin"                          # override with DOTRUN_BIN_DIR

# ------------------------------------------------------------------
# 1.  Guard against clobbering existing config dir
# ------------------------------------------------------------------
if [[ -d "$CFG_DIR" && -n "$(ls -A "$CFG_DIR")" ]]; then
  echo "⚠️  $CFG_DIR already exists; will only copy new files."
else
  mkdir -p "$CFG_DIR"
fi

# ------------------------------------------------------------------
# 2.  Copy repo without overwriting existing files
# ------------------------------------------------------------------
if command -v rsync >/dev/null 2>&1; then
  rsync -a --ignore-existing --exclude ".git" "$SRC_DIR"/ "$CFG_DIR"/
else
  echo "rsync not found — using tar fallback (no files will be overwritten)"
  ( cd "$SRC_DIR" && tar --exclude=.git -cf - . ) \
      | tar -xf - --keep-old-files -C "$CFG_DIR"
fi

# ------------------------------------------------------------------
# 3.  Install drun binary into PATH
# ------------------------------------------------------------------
TARGET_DIR="${DOTRUN_BIN_DIR:-$BIN_DEST}"
if [[ ! -w "$TARGET_DIR" ]]; then
  TARGET_DIR="$HOME/.local/bin"
  mkdir -p "$TARGET_DIR"
  if ! grep -q "$TARGET_DIR" <<<"$PATH"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
    echo "• Added \$HOME/.local/bin to PATH in ~/.bashrc"
  fi
fi
install -m 755 "$CFG_DIR/bin/drun" "$TARGET_DIR/drun"
echo "• drun copied to $TARGET_DIR/drun"

# ------------------------------------------------------------------
# 4.  Completion (bash example)
# ------------------------------------------------------------------
COMPLETION_DST="${HOME}/.config/bash_completion.d/drun"
mkdir -p "$(dirname "$COMPLETION_DST")"
cp "$CFG_DIR/drun_completion" "$COMPLETION_DST"
echo "• completion copied to $COMPLETION_DST"

echo -e "\n✅  DotRun installed!"
echo "   Config dir : $CFG_DIR"
echo "   Binary     : $(command -v drun)"

