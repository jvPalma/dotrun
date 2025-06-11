# branchSlice — create a sliced branch from the default branch

### Synopsis

`branchSlice <new-branch>`

### Description

1. Saves the current branch name to `~/.sliced-pr`.
2. Resets/creates `<new-branch>` from the repo’s default branch (resolved via
   remote HEAD or `GIT_DEFAULT_BRANCH`).
3. Copies staged and unstaged changes from the original branch.

### Arguments

| Pos | Name       | Description                         |
| --: | ---------- | ----------------------------------- |
|   1 | new-branch | Name of the sliced branch to create |

### Example

```bash
$ git checkout -b feature/add-login
# …hack hack…
$ drun branchSlice review/add-login
Switched to a new branch 'review/add-login' based on 'master'
```
