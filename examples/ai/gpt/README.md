# gpt — generate analysis-ready report of a source tree

### Synopsis

`gpt <directory>`

### Description

Scans `<directory>`, skips large or irrelevant files, collates a project tree,
language histogram (via `cloc` when available) and the contents of qualifying
files into `gpt.out`, then opens that file in `$EDITOR` (default `nano`).

### Arguments

| Pos | Name      | Description                         |
| --: | --------- | ----------------------------------- |
|   1 | directory | Path to the project root to analyse |

### Example

```bash
$ drun gpt ./folder/my-app
Done. Log saved to: /home/user/current_directory/gpt.out
# gpt.out now opens in your editor
```

Produces `gpt.out` with the tree, cloc histogram and file excerpts.
