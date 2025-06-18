#!/usr/bin/env bash
### DOC
#   Create Hook
### DOC

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

# source "$DRUN_CONFIG/helper.sh"

main() {
  if [ "$#" -eq 0 ]; then
    echo "Error: Please provide a hook name."
    return 1
  fi

  local HOOK_NAME="$1"
  local HOOK_DIR="./${HOOK_NAME}"
  local HOOK_FUNCTION="use${HOOK_NAME}"
  local PROVIDER_NAME="${HOOK_NAME}Provider"

  mkdir -p "$HOOK_DIR"

  printf "export * from './%s';\nexport * from './%s';\n" "$HOOK_FUNCTION" "$PROVIDER_NAME" >"$HOOK_DIR/index.ts"

  {
    printf "import { createContext, useContext } from 'react';\n\n"
    printf "type %sContextType = {\n  message?: string;\n};\n\n" "$HOOK_NAME"
    printf "const %sContext = createContext<%sContextType | undefined>(undefined);\n\n" "$HOOK_NAME" "$HOOK_NAME"
    printf "export const %s = () => {\n  const context = useContext(%sContext);\n  if (!context){\n    throw new Error('%s must be used within a %s');\n  }\n  return context;\n};\n\n" "$HOOK_FUNCTION" "$HOOK_NAME" "$HOOK_FUNCTION" "$PROVIDER_NAME"
    printf "export { %sContext };\n" "$HOOK_NAME"
  } >"$HOOK_DIR/${HOOK_FUNCTION}.ts"

  {
    printf "import React from 'react';\nimport { %sContext } from './%s';\n\n" "$HOOK_NAME" "$HOOK_FUNCTION"
    printf "export const %s: React.FC<{ children: React.ReactNode }> = ({ children }) => {\n  const value = {\n    message: 'Hello from context'\n  };\n\n  return (\n    <%sContext.Provider value={value}>\n      {children}\n    </%sContext.Provider>\n  );\n};\n" "$PROVIDER_NAME" "$HOOK_NAME" "$HOOK_NAME"
  } >"$HOOK_DIR/${PROVIDER_NAME}.tsx"

  {
    printf "import React from 'react';\nimport { render, screen } from '@testing-library/react';\nimport { %s, %s } from './index';\n\n" "$PROVIDER_NAME" "$HOOK_FUNCTION"
    printf "const TestComponent = () => {\n  const { message } = %s();\n  return <div>{message}</div>;\n};\n\n" "$HOOK_FUNCTION"
    printf "describe('%s Hook', () => {\n  it('should throw error when used outside provider', () => {\n    const ErrorComponent = () => {\n      try {\n        %s();\n        return null;\n      } catch (error){\n        return <div>{error.message}</div>;\n      }\n    };\n\n    render(<ErrorComponent />);\n    expect(screen.getByText(/%s must be used within a %s/i)).toBeVisible();\n  });\n\n" "$HOOK_FUNCTION" "$HOOK_FUNCTION" "$HOOK_FUNCTION" "$PROVIDER_NAME"
    printf "  it('should return context value when used within provider', () => {\n    render(\n      <%s>\n        <TestComponent />\n      </%s>\n    );\n    expect(screen.getByText(/Hello from context/i)).toBeVisible();\n  });\n});\n" "$PROVIDER_NAME" "$PROVIDER_NAME"
  } >"$HOOK_DIR/${HOOK_NAME}.test.tsx"

  echo "Hook $HOOK_FUNCTION created successfully."
}
main "$@"
