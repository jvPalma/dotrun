#!/usr/bin/env bash
# shellcheck disable=SC2034

USEFULL_VARIABLE="MY_SECRET"

usefullFunction() {
  echo "This is a usefull function that can be used in any script"
  echo "The secret is: $USEFULL_VARIABLE"
}
