# Script template

## Files struct/organization

When we do `drun add myCoolScript` it will be created in the `~/.config/dotrun/` location the following files:
NOTE: the helper must be created manually for now!

```bash
~/.config/dotrun/
├── bin/
│   └── myCoolScript.sh
├── docs/
│   └── myCoolScript.md
└── helpers/
    └── myCoolHelper.sh

4 directories, 3 files
```

## Language Histogram

| Language | # Files | # Lines |
| :------- | ------: | ------: |
| bash     |       2 |      31 |
| markdown |       1 |      20 |

## File Contents

#### ./bin/myCoolScript.sh ------------

```bash
#!/usr/bin/env bash
### DOC
#   One-line description of the script.
### DOC
## add command: drun add <scriptName>

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

## create or use any helper files from `$DRUN_CONFIG/helpers/`
source "$DRUN_CONFIG/helpers/myCoolHelper.sh"

main() {
  # loaded from helpers/myCoolHelper.sh
  usefullFunction

  echo "scriptName logic in this main"
}

main "$@"
```

#### ./docs/myCoolScript.md ------------

````markdown
# myCoolScript — This script prints my cool secrets

## Overview

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec elit lorem, ullamcorper ut purus sit amet, volutpat sollicitudin massa. Etiam porta luctus quam quis bibendum. Fusce eget magna lorem. Nulla ultricies ultricies orci quis faucibus. Integer facilisis sodales elit id faucibus. Nulla sit amet tempor est.

## Features

- does this
- that
- also this
- finally this too

## Examples

```bash
$ drun myCoolScript
```

```

## any other usefull sections and descriptions if applied.

```
````
