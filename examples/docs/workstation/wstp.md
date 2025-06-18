# wstp — Stop Cloud Workstation

Stops your Google Cloud Workstation if it's currently running, with intelligent status checking and graceful shutdown handling.

## Synopsis

```bash
drun workstation/wstp
```

## Description

Initiates the shutdown process for your configured cloud workstation. The script first verifies the workstation is running before attempting to stop it, ensuring clean operations and providing clear feedback.

Features:
- **Status validation**: Verifies workstation is running before shutdown
- **Graceful shutdown**: Uses proper API calls for clean workstation shutdown
- **Clear feedback**: Provides status messages for all scenarios
- **Cost optimization**: Helps reduce compute costs when development is finished

## Usage

```bash
# Stop running workstation
drun workstation/wstp

# Use in end-of-day automation
drun workstation/wstp
echo "Workstation stopped - have a great day!"
```

## Behavior

### Workstation Running
```bash
$ drun workstation/wstp
Stopping workstation...
# Waits for shutdown completion
Workstation stopped successfully.
```

### Workstation Already Stopped
```bash
$ drun workstation/wstp
Workstation is not running.
```

### Workstation Stopping
```bash
$ drun workstation/wstp
Workstation is already stopping.
```

## Cost Considerations

- **Resource billing**: Stopping workstations reduces compute costs
- **Persistent storage**: Data remains available after shutdown
- **Startup time**: Consider restart time when planning shutdown
- **Automation**: Use scheduled shutdown for cost optimization

## Prerequisites

- **Google Cloud CLI** configured and authenticated
- **Workstation configuration** defined in `helpers/constants.sh`
- **Proper IAM permissions** to stop workstations
- **Active workstation** to perform shutdown

## Safety Notes

- **Save work**: Ensure all work is saved before shutdown
- **Active connections**: Will terminate SSH sessions
- **Running processes**: Background processes will be stopped
- **Graceful shutdown**: Allows proper process termination

## Related Commands

- **wsl** - Check workstation status
- **wss** - Start stopped workstation
- **wsc** - Connect to workstation (with auto-start)

## See Also

- [wsl.md](./wsl.md) - Check workstation status
- [wss.md](./wss.md) - Start workstation
- [wsc.md](./wsc.md) - SSH connection with auto-start
