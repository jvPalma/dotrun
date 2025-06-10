#!/usr/bin/env bash

source "$HELPERS_PATH/constants.sh"

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
