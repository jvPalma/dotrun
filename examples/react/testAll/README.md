# testAll — run all Jest tests and capture failing files

### Synopsis

`testAll`

### Description

Runs `yarn test --watchAll=false`, stores full output in `test_output.out`, then
extracts failing test file paths into `files_with_error.out` (deduped) replacing
the word _FAIL_ with `clear; yarn test`.

### Example

```bash
$ drun testAll
Failed test file paths have been saved to /project/files_with_error.out
```
