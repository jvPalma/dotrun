# wss — Start Cloud Workstation

Starts your Google Cloud Workstation if it's currently stopped, with intelligent status checking to avoid unnecessary operations.

## Synopsis

```bash
drun workstation/wss
```

## Description

Initiates the startup process for your configured cloud workstation. The script first checks the current status and only starts the workstation if it's currently stopped, preventing unnecessary restart operations.

Features:
- **Status validation**: Checks current state before attempting startup
- **Idempotent operation**: Safe to run multiple times
- **Clear feedback**: Provides status messages for all scenarios
- **Error handling**: Graceful handling of startup failures

## Usage

```bash
# Start workstation if stopped
drun workstation/wss

# Use in automation scripts
if [[ "$(drun workstation/wsl)" != "RUNNING" ]]; then
  drun workstation/wss
fi
```

## Behavior

### Workstation Already Running
```bash
$ drun workstation/wss
Workstation is already running.
```

### Workstation Starting
```bash
$ drun workstation/wss
Starting workstation...
# Waits for startup completion
Workstation started successfully.
```

### Workstation Stopped
```bash
$ drun workstation/wss
Workstation is stopped. Starting now...
# Initiates startup process
```

## Prerequisites

- **Google Cloud CLI** configured and authenticated
- **Workstation configuration** defined in `helpers/constants.sh`
- **Proper IAM permissions** to start workstations
- **Billing account** active for compute resources

## Related Commands

- **wsl** - Check workstation status
- **wsc** - Connect to workstation (with auto-start)
- **wstp** - Stop running workstation

## See Also

- [wsl.md](./wsl.md) - Check workstation status
- [wsc.md](./wsc.md) - SSH connection with auto-start
- [wstp.md](./wstp.md) - Stop workstation
