# branchGetSlicedCode — copy code from a sliced branch

### Synopsis

`branchGetSlicedCode`

### Description

Checks out the branch recorded in `~/.sliced-pr` _into the working tree only_
(keeps HEAD unchanged), then resets the index. Handy when you need the code of
a PR branch while staying on another branch.

### Example

```bash
$ drun branchGetSlicedCode
# Working tree now contains the files of the sliced branch
```
