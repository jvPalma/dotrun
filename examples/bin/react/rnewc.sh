#!/usr/bin/env bash
### DOC
#   Create Component
### DOC
## add command: drun add rnewc

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

# source "$DRUN_CONFIG/helper.sh"

main() {
  if [ "$#" -eq 0 ]; then
    echo "Error: Please provide a component name or path."
    return 1
  fi

  local input="$1"
  local COMPONENT_NAME
  local COMPONENT_DIR
  local COMPONENT_DIR_INDEX

  if [[ "$input" == *"/"* ]]; then
    # Input contains a folder path.
    COMPONENT_NAME=$(basename "$input")
    COMPONENT_DIR="$input"
    COMPONENT_DIR_INDEX="$COMPONENT_DIR/index.ts"

    if [ ! -d "$COMPONENT_DIR" ]; then
      mkdir -p "$COMPONENT_DIR"
      # Create the barrel file with an export line.
      printf "export * from './%s';\n" "$COMPONENT_NAME" >"$COMPONENT_DIR_INDEX"
    else
      # If the directory exists, update (or create) the index barrel file.
      local export_line
      export_line=$(printf "export * from './%s';" "$COMPONENT_NAME")
      if [ -f "$COMPONENT_DIR_INDEX" ]; then
        if ! grep -Fq "$export_line" "$COMPONENT_DIR_INDEX"; then
          printf "\n%s\n" "$export_line" >>"$COMPONENT_DIR_INDEX"
        fi
      else
        printf "%s\n" "$export_line" >"$COMPONENT_DIR_INDEX"
      fi
    fi
  else
    # Only a component name was provided; use a folder with the same name in the current directory.
    COMPONENT_NAME="$input"
    COMPONENT_DIR="./${COMPONENT_NAME}"
    COMPONENT_DIR_INDEX="${COMPONENT_DIR}/index.ts"
    mkdir -p "$COMPONENT_DIR"
    printf "export * from './%s';\n" "$COMPONENT_NAME" >"$COMPONENT_DIR_INDEX"
  fi

  local COMPONENT_PROP_TYPE="${COMPONENT_NAME}Props"

  # Create the component file.
  printf "\ntype %s = {\n  field?: string;\n}\n\nexport const %s = ({ field: _field } : %s) => {\n  return (\n    <div>\n      %s Component\n    </div>\n  );\n};\n" \
    "$COMPONENT_PROP_TYPE" "$COMPONENT_NAME" "$COMPONENT_PROP_TYPE" "$COMPONENT_NAME" \
    >"$COMPONENT_DIR/${COMPONENT_NAME}.tsx"

  # Create the test file.
  printf "import { render, screen } from '@testing-library/react';\n\nimport { %s } from './index';\n\ndescribe('%s', () => {\n  it('should render the component content correctly', () => {\n    render(<%s />);\n\n    expect(screen.getByText(/%s/i)).toBeVisible();\n  });\n});\n" \
    "$COMPONENT_NAME" "$COMPONENT_NAME" "$COMPONENT_NAME" "$COMPONENT_NAME" \
    >"$COMPONENT_DIR/${COMPONENT_NAME}.test.tsx"

  echo "Component $COMPONENT_NAME created successfully in $COMPONENT_DIR."
}
main "$@"
