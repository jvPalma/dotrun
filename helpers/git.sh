#!/usr/bin/env bash
#
# Re-usable Git helpers for any drun script
#
source "$DOTRUN_PREFIX/helpers/pkg.sh"

validatePkg git

# ──────────────────────────────────────────────────────────────
# Return absolute repo root, or exit 1 if not inside a repo.
git_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null ||
    {
      echo "Not inside a Git repo" >&2
      return 1
    }
}

# Current branch name
git_current_branch() {
  git symbolic-ref --quiet --short HEAD
}

# Default branch for this repo
# 1. honour env GIT_DEFAULT_BRANCH
# 2. honour remote HEAD (origin/HEAD → origin/<main>)
# 3. fallback to 'master'
git_default_branch() {
  [[ -n "${GIT_DEFAULT_BRANCH:-}" ]] && {
    echo "$GIT_DEFAULT_BRANCH"
    return
  }

  local d
  d=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) || true
  d=${d#origin/}
  echo "${d:-master}"
}

# Change directory to repo root (silently)
cd_repo_root() { cd "$(git_repo_root)" || return 1; }
