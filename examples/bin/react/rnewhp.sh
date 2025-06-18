#!/usr/bin/env bash
### DOC
#   Create Provider with Hook for its context
### DOC

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

  input="$1"
  COMPONENT_NAME=$(basename "$input")

  # Determine the target directory
  if [[ "$input" == *"/"* ]]; then
    TARGET_DIR="$input"
    # If the folder does not exist, create it with an index barrel file
    if [ ! -d "$TARGET_DIR" ]; then
      mkdir -p "$TARGET_DIR"
      echo "export * from './use${COMPONENT_NAME}';" >"$TARGET_DIR/index.ts"
    else
      # If the folder exists, check for an index barrel file and add an export line if missing
      INDEX_FILE="$TARGET_DIR/index.ts"
      export_line="export * from './use${COMPONENT_NAME}';"
      if [ -f "$INDEX_FILE" ]; then
        if ! grep -Fq "$export_line" "$INDEX_FILE"; then
          echo "$export_line" >>"$INDEX_FILE"
        fi
      else
        echo "$export_line" >"$INDEX_FILE"
      fi
    fi
  else
    # If no folder path is provided, create the component folder prefixed with "use"
    TARGET_DIR="./use${COMPONENT_NAME}"
    mkdir -p "$TARGET_DIR"
    echo "export * from './use${COMPONENT_NAME}';" >"$TARGET_DIR/index.ts"
  fi

  # Create the hook provider file with boilerplate code, substituting the component name
  cat >"$TARGET_DIR/use${COMPONENT_NAME}.tsx" <<EOF
import { ReactNode, createContext, useContext, useMemo } from 'react';

type ${COMPONENT_NAME}ProviderProps = {
  children: ReactNode;
};

export type ${COMPONENT_NAME}Context = {
  isOpen: boolean;
  toggleOpen: () => void;
};

const initialState: ${COMPONENT_NAME}Context = {
  isOpen: false,
  toggleOpen: () => {},
};

const ProviderContext = createContext<${COMPONENT_NAME}Context>(initialState);

export const ${COMPONENT_NAME}Provider = ({
  children,
}: ${COMPONENT_NAME}ProviderProps) => {
  const providerValue: ${COMPONENT_NAME}Context = useMemo(
    () => ({ ...initialState }),
    [],
  );

  return (
    <ProviderContext.Provider value={providerValue}>
      {children}
    </ProviderContext.Provider>
  );
};

export const use${COMPONENT_NAME} = () => {
  const context = useContext(ProviderContext);
  if (!context) {
    throw new Error(
      'use${COMPONENT_NAME} must be used within a ${COMPONENT_NAME}Provider'
    );
  }
  return context;
};
EOF

  # Create a boilerplate test file for the hook provider initial state
  cat >"$TARGET_DIR/use${COMPONENT_NAME}.test.tsx" <<EOF
import { render } from '@testing-library/react';

import {
  ${COMPONENT_NAME}Provider,
  use${COMPONENT_NAME},
} from './use${COMPONENT_NAME}';

describe('${COMPONENT_NAME}Provider', () => {
  it('should initialize with isOpen as false', () => {
    let contextValue: undefined | ReturnType<typeof use${COMPONENT_NAME}>;
    const Dummy = () => {
      contextValue = use${COMPONENT_NAME}();
      return null;
    };

    render(
      <${COMPONENT_NAME}Provider>
        <Dummy />
      </${COMPONENT_NAME}Provider>
    );

    expect(contextValue?.isOpen).toBe(false);
  });
});
EOF

  echo "Hook provider component ${COMPONENT_NAME} created successfully in ${TARGET_DIR}"
}
main "$@"
