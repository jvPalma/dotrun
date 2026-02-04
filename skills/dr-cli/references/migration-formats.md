# DotRun File Formats

> File templates and naming conventions for aliases, configs, and scripts.

## Directory Structure

```
~/.config/dotrun/
├── aliases/      # *.aliases
├── configs/      # *.config
├── scripts/      # *.sh (organized by category)
└── helpers/      # *.sh (reusable functions)
```

---

## Alias Files

**Location**: `~/.config/dotrun/aliases/`
**Naming**: `NN-category.aliases` (NN = load order 00-99)

```bash
#!/usr/bin/env bash
# DotRun Aliases - Git
# Migrated from: ~/.zshrc on YYYY-MM-DD

alias gs='git status -sb'
alias gc='git commit -m'

# Shell-specific
[[ $CURRENT_SHELL == "bash" ]] && {
  alias drr="source ~/.bashrc"
}

[[ $CURRENT_SHELL == "zsh" ]] && {
  alias drr="source ~/.zshrc"
}

# DotRun script aliases
alias co="dr git/branch/co"
```

---

## Config Files

**Location**: `~/.config/dotrun/configs/`
**Naming**: `NN-category.config` or `NN.category.config`

```bash
#!/usr/bin/env bash
# DotRun Config - Paths

export PATH="$HOME/.local/bin:$PATH"

# Conditional tool setup
if command -v brew >/dev/null 2>&1; then
  eval "$($(brew --prefix)/bin/brew shellenv)"
fi

[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

**Secure configs** go in `~/.config/dotrun/configs/00.secure/` with 600 permissions.

---

## Script Files

**Location**: `~/.config/dotrun/scripts/{category}/`
**Naming**: `scriptName.sh`

### Simple Script

```bash
#!/usr/bin/env bash
### DOC
# Display current git branch
### DOC
# Usage: dr git/branch/name
### DOC

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"
loadHelpers git/git

echo "$(git_current_branch)"
```

### Full Template

```bash
#!/usr/bin/env bash
### DOC
# One-line description
### DOC
#
# Usage: dr category/name [OPTIONS] <args>
#
# Options:
#   -f, --file    Description
#   -h, --help    Show help
#
### DOC

set -euo pipefail

[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/colors
loadHelpers global/logging

showHelp() {
  cat <<'EOF'
Usage: dr category/name [OPTIONS] <args>

Options:
  -f, --file    Description
  -h, --help    Show this help
EOF
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) showHelp; exit 0 ;;
      -f|--file) file="$2"; shift 2 ;;
      -*) log_error "Unknown: $1"; exit 1 ;;
      *) arg="$1"; shift ;;
    esac
  done

  log_info "Running..."
}

main "$@"
```

---

## Naming Conventions

### Load Order

```
00-shell-specific.aliases   # First
01-navigation.aliases       # Early
10-code-navigation.aliases  # Mid
15-git.aliases              # Mid
40-custom.aliases           # Late
```

### Variables

- **Exports**: UPPERCASE (`GIT_USERNAME`, `EDITOR`)
- **Constants**: UPPERCASE (`MIN_SIZE`, `OUTPUT_DIR`)
- **Locals**: lowercase (`local file=""`)

---

## DOC Block Format

```bash
### DOC
# Short description (shown in dr -L)
### DOC
#
# Extended description (shown in dr help name)
# Usage, options, examples
#
### DOC
```

---

## Migration Checklist

**Aliases:**

- [ ] Rename to `NN-category.aliases`
- [ ] Add header comment
- [ ] Replace script calls with `dr category/script`

**Configs:**

- [ ] Rename to `NN-category.config`
- [ ] Use `export` for all env vars
- [ ] Move secrets to `00.secure/`

**Scripts:**

- [ ] Create category directory
- [ ] Add `### DOC` blocks
- [ ] Add `set -euo pipefail`
- [ ] Add loadHelpers boilerplate
- [ ] Wrap logic in `main()`
