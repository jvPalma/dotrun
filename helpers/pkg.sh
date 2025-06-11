#!/usr/bin/env bash
# helpers/pkg.sh – package-manager helpers

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

detect_lang() {
  case "${1##*.}" in
  js) echo javascript ;;
  ts) echo typescript ;;
  py) echo python ;;
  sh) echo bash ;;
  rb) echo ruby ;;
  go) echo go ;;
  rs) echo rust ;;
  java) echo java ;;
  css) echo css ;;
  html | htm) echo html ;;
  json) echo json ;;
  yml | yaml) echo yaml ;;
  md) echo markdown ;;
  *) echo "" ;;
  esac
}

pkg_install_hint() {
  local tool="$1"
  if command -v apt &>/dev/null; then
    echo "sudo apt install $tool"
  elif command -v dnf &>/dev/null; then
    echo "sudo dnf install $tool"
  elif command -v pacman &>/dev/null; then
    echo "sudo pacman -S $tool"
  elif command -v brew &>/dev/null; then
    echo "brew install $tool"
  elif command -v pkg &>/system/bin; then
    echo "pkg install $tool" # Termux
  else
    echo "Install '$tool' via your package manager"
  fi
}

#
validatePkg() {
  local tool="$1"
  command -v "$tool" &>/dev/null && return

  echo "'$tool' is missing – install it with:"
  echo "  $(pkg_install_hint "$tool")"
  exit 1
}
