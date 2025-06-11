#!/usr/bin/env bash

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

source "$DRUN_CONFIG/helpers/constants.sh"

workstationConfigs() {
  local cmd="$1"
  shift
  local project="--project=$WS_PROJECT"
  local cluster="--cluster=$WS_CLUSTER"
  local config="--config=$WS_CONFIG"
  local region="--region=$WS_REGION"
  local wrkst="$WS_WRKST"

  if [[ "$cmd" == "list" ]]; then
    gcloud workstations "$cmd" "$project" "$cluster" "$config" "$region" |
      grep "$wrkst" |
      awk '{print $5}'
  else
    gcloud workstations "$cmd" "$project" "$cluster" "$config" "$region" "$wrkst" "$@"
  fi

}
