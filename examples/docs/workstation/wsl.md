# wsl — Cloud Workstation Status Checker

Quick status check for your Google Cloud Workstation, providing instant visibility into current workstation state.

## Synopsis

```bash
drun workstation/wsl
```

## Description

Queries the Google Cloud Workstations API to check the current status of your configured workstation. This command provides a fast way to verify workstation state before attempting connections or operations.

The script lists all workstations in the configured cluster and extracts the status for your specific workstation as defined in the constants configuration.

## Output States

| Status | Meaning |
|--------|---------|
| `RUNNING` | Workstation is active and ready for connections |
| `STOPPED` | Workstation is stopped and needs to be started |
| `STARTING` | Workstation is currently booting up |
| `STOPPING` | Workstation is in the process of shutting down |

## Usage

```bash
# Check current workstation status
drun workstation/wsl

# Use in scripts for conditional logic
if [[ "$(drun workstation/wsl)" == "RUNNING" ]]; then
  echo "Workstation is ready"
else
  echo "Workstation needs to be started"
fi
```

## Examples

### Basic Status Check
```bash
$ drun workstation/wsl
RUNNING
```

### Script Integration
```bash
#!/bin/bash
STATUS=$(drun workstation/wsl)
case "$STATUS" in
  "RUNNING")
    echo "✓ Workstation is ready for connection"
    ;;
  "STOPPED")
    echo "○ Workstation is stopped - use 'drun wss' to start"
    ;;
  "STARTING")
    echo "⏳ Workstation is starting up..."
    ;;
  *)
    echo "? Unknown status: $STATUS"
    ;;
esac
```

## Prerequisites

- **Google Cloud CLI** configured and authenticated
- **Workstation configuration** defined in `helpers/constants.sh`
- **Proper IAM permissions** to list workstations

## Configuration

Workstation details must be configured in:
```bash
# $DRUN_CONFIG/helpers/constants.sh
WORKSTATION_NAME="your-workstation"
WORKSTATION_CLUSTER="your-cluster"
WORKSTATION_CONFIG="your-config"
```

## Related Commands

- **wsc** - Connect to workstation (with auto-start)
- **wss** - Start workstation if stopped
- **wstp** - Stop running workstation

## See Also

- [wsc.md](./wsc.md) - SSH connection with auto-start
- [wss.md](./wss.md) - Manual workstation startup
- [wstp.md](./wstp.md) - Manual workstation shutdown
