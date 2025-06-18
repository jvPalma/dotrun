#!/usr/bin/env bash
### DOC
# prStats - describe what this script does
### DOC

#!/usr/bin/env bash
# full_pr_audit.sh
# Usage: ./full_pr_audit.sh <owner/repo> <label-name>
# Example: ./full_pr_audit.sh myorg/myrepo "qa-approved"
#
# Requires: GitHub CLI (`gh`) and `jq`

set -euo pipefail

GH_MAX_RETRIES=${GH_MAX_RETRIES:-15}
GH_TIMEOUT=${GH_TIMEOUT:-140}

fetch_json() {
  local tries=0
  while (( tries < GH_MAX_RETRIES )); do
    if JSON=$(timeout "${GH_TIMEOUT}s" gh api "$@" 2>/dev/null); then
      echo "$JSON"
      return 0
    fi
    ((tries++))
    sleep $((tries * 5))
  done
  return 1
}

#!/usr/bin/env bash
# full_pr_audit.sh
# Usage: ./full_pr_audit.sh <owner/repo> <label-name>
# Example: ./full_pr_audit.sh myorg/myrepo "qa-approved"
#
# Requires: GitHub CLI (`gh`) and `jq`

set -euo pipefail

REPO="${1:-}"
LABEL="${2:-}"

if [[ -z "$REPO" || -z "$LABEL" ]]; then
  echo "Usage: $0 <owner/repo> <label-name>" >&2
  exit 1
fi

echo "number,created_at,label_added_at,requested_reviewers,reviewers,merged_at,secs_created→label,secs_label→merged"

# Fetch up to 500 merged PRs you authored
mapfile -t PRS < <(gh pr list --repo "$REPO" \
                              --author @me --state merged --limit 500 \
                              --json number \
                              --template '{{range .}}{{.number}}{{"\n"}}{{end}}')

for PR in "${PRS[@]}"; do
  # Basic PR metadata
  PR_JSON=$(gh api "repos/$REPO/pulls/$PR")
  CREATED=$(jq -r '.created_at' <<<"$PR_JSON")
  MERGED=$(jq -r '.merged_at'  <<<"$PR_JSON")

if ! PR_JSON=$(fetch_json "repos/$REPO/pulls/$PR"); then
  echo "WARN: unable to fetch PR #$PR after $GH_MAX_RETRIES attempts" >&2
  continue
fi

LABEL_EVENTS=$(fetch_json --paginate "repos/$REPO/issues/$PR/events") || LABEL_EVENTS=""
LABEL_TIME=$(echo "$LABEL_EVENTS" | jq -r --arg L "$LABEL" '
  map(select(.event=="labeled" and .label.name==$L))
  | sort_by(.created_at)
  | .[0].created_at // empty')

REQ_REVS_JSON=$(fetch_json "repos/$REPO/pulls/$PR/requested_reviewers") || REQ_REVS_JSON="{}"
REQ_REVS=$(echo "$REQ_REVS_JSON" | jq -r '.users[].login' | paste -sd, -)

REVIEWS_JSON=$(fetch_json --paginate "repos/$REPO/pulls/$PR/reviews") || REVIEWS_JSON="[]"
REVIEWERS=$(echo "$REVIEWS_JSON" | jq -r '.[].user.login' | sort -u | paste -sd, -)

  # Time deltas (seconds)
  if [[ -n "$LABEL_TIME" ]]; then
    DELTA_1=$(( $(date -d "$LABEL_TIME" +%s) - $(date -d "$CREATED" +%s) ))
    DELTA_2=$(( $(date -d "$MERGED"     +%s) - $(date -d "$LABEL_TIME" +%s) ))
  else
    DELTA_1=
    DELTA_2=
  fi

  echo "$PR,$CREATED,$LABEL_TIME,$REQ_REVS,$REVIEWERS,$MERGED,$DELTA_1,$DELTA_2"
done

