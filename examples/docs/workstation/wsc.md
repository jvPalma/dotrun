# wsc — SSH into Cloud Workstation

Intelligent SSH connection to your Google Cloud Workstation with automatic startup detection and shell preference.

## Synopsis

```bash
drun workstation/wsc
```

## Description

Establishes an SSH connection to your configured cloud workstation, automatically handling the startup sequence if needed. The script intelligently checks workstation status and starts it if not running, ensuring seamless access to your remote development environment.

Features:
- **Smart Status Detection**: Checks if workstation is running before connecting
- **Automatic Startup**: Starts workstation if currently stopped
- **Fish Shell Default**: Connects with fish shell for enhanced experience
- **Error Handling**: Graceful handling of connection and startup failures

## Usage

```bash
# Connect to running workstation
drun workstation/wsc

# If workstation is stopped, automatically starts it first
drun workstation/wsc
```

## Behavior

### Workstation Running
```bash
$ drun workstation/wsc
SSH into workstation...
# Direct connection established
```

### Workstation Stopped
```bash
$ drun workstation/wsc
Workstation is not running. Starting it now...
# Waits for startup completion
SSH into workstation...
# Connection established after startup
```

## Prerequisites

- **Google Cloud CLI** configured and authenticated
- **Cloud Workstation** properly configured in `helpers/constants.sh`
- **SSH access** configured for the workstation
- **Network connectivity** to Google Cloud

## Configuration

Workstation connection details are defined in:
```bash
# $DRUN_CONFIG/helpers/constants.sh
WORKSTATION_NAME="your-workstation"
WORKSTATION_CLUSTER="your-cluster"
WORKSTATION_CONFIG="your-config"
```

## Related Commands

- **wsl** - Check workstation status
- **wss** - Start workstation if stopped
- **wstp** - Stop running workstation

## See Also

- [wsl.md](./wsl.md) - Check workstation status
- [wss.md](./wss.md) - Start workstation manually
- [wstp.md](./wstp.md) - Stop workstation
