#!/usr/bin/env bash
### DOC
#   Run all tests and save the paths of files with errors
### DOC
## add command: drun add testAll

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

# source "$DRUN_CONFIG/helper.sh"

main() {
  yarn test --silent --watchAll=false >test_output.out 2>&1

  # Extract the paths of files with errors and save them to files_with_error.out in the current directory
  grep "FAIL" test_output.out >files_with_error.out

  # Remove duplicated lines in the files_with_error.out file
  sort -u files_with_error.out -o files_with_error.out

  # Replace all "FAIL" strings with "clear; yarn test" in files_with_error.out
  sed -i 's/FAIL/clear; yarn test/g' files_with_error.out

  echo "Failed test file paths have been saved to $(pwd)/files_with_error.out"
}

main "$@"
