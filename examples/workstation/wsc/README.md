# wsc — SSH into the Cloud Workstation

### Synopsis

`wsc`

### Description

If the workstation is _RUNNING_ (checked via `drun wsl`), SSH in with a `fish`
shell; otherwise starts it first.

### Example

```bash
$ drun wsc
SSH into workstation...
# (or)
Workstation is not running. Starting it now...
SSH into workstation...
```
