# System Administration Scripts

Collection of system administration and maintenance scripts for Linux/macOS environments.

## Log Cleanup and Rotation

Clean up system and application logs to free disk space.

```bash
#!/usr/bin/env bash
### DOC
# Clean up system logs and rotate log files
### DOC
set -euo pipefail

# Configuration
MAX_LOG_SIZE="100M"
RETENTION_DAYS=30
LOG_DIRS=(
    "/var/log"
    "$HOME/.local/share/logs"
    "$HOME/.cache/logs"
    "/tmp"
)

echo "🧹 System Log Cleanup"
echo "====================="

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$(( bytes / 1073741824 ))GB"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$(( bytes / 1048576 ))MB"
    elif [ "$bytes" -gt 1024 ]; then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "${bytes}B"
    fi
}

# Calculate initial disk usage
INITIAL_USAGE=$(df / | awk 'NR==2 {print $3}')
echo "📊 Initial disk usage: $(format_bytes $((INITIAL_USAGE * 1024)))"

# Clean journal logs (systemd)
if command -v journalctl > /dev/null 2>&1; then
    echo ""
    echo "📰 Cleaning journal logs..."
    JOURNAL_SIZE_BEFORE=$(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[A-Z]*' | head -1 || echo "0")

    # Clean logs older than retention period
    sudo journalctl --vacuum-time="${RETENTION_DAYS}d" 2>/dev/null || true
    sudo journalctl --vacuum-size=100M 2>/dev/null || true

    JOURNAL_SIZE_AFTER=$(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[A-Z]*' | head -1 || echo "0")
    echo "   Before: $JOURNAL_SIZE_BEFORE"
    echo "   After: $JOURNAL_SIZE_AFTER"
fi

# Clean application logs
echo ""
echo "📁 Cleaning application logs..."

for log_dir in "${LOG_DIRS[@]}"; do
    if [ -d "$log_dir" ]; then
        echo "   Processing: $log_dir"

        # Find and clean old log files
        find "$log_dir" -name "*.log" -mtime +$RETENTION_DAYS -type f 2>/dev/null | \
        while IFS= read -r logfile; do
            if [ -f "$logfile" ]; then
                FILE_SIZE=$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null || echo 0)
                echo "     Removing: $(basename "$logfile") ($(format_bytes $FILE_SIZE))"
                rm -f "$logfile"
            fi
        done

        # Compress large current log files
        find "$log_dir" -name "*.log" -size +$MAX_LOG_SIZE -type f 2>/dev/null | \
        while IFS= read -r logfile; do
            if [ -f "$logfile" ]; then
                echo "     Compressing: $(basename "$logfile")"
                gzip "$logfile" 2>/dev/null || true
            fi
        done
    fi
done

# Clean temporary files
echo ""
echo "🗑️  Cleaning temporary files..."
TMP_CLEANED=0

# Clean /tmp files older than 7 days
if [ -d "/tmp" ]; then
    find /tmp -type f -mtime +7 2>/dev/null | \
    while IFS= read -r tmpfile; do
        if [ -f "$tmpfile" ]; then
            FILE_SIZE=$(stat -f%z "$tmpfile" 2>/dev/null || stat -c%s "$tmpfile" 2>/dev/null || echo 0)
            TMP_CLEANED=$((TMP_CLEANED + FILE_SIZE))
            rm -f "$tmpfile" 2>/dev/null || true
        fi
    done
fi

# Clean user cache directories
echo ""
echo "💾 Cleaning cache directories..."
CACHE_DIRS=(
    "$HOME/.cache"
    "$HOME/.local/share/Trash"
    "$HOME/Library/Caches" # macOS
)

for cache_dir in "${CACHE_DIRS[@]}"; do
    if [ -d "$cache_dir" ]; then
        echo "   Processing: $cache_dir"
        find "$cache_dir" -type f -mtime +$RETENTION_DAYS 2>/dev/null | \
        head -100 | \
        while IFS= read -r cachefile; do
            if [ -f "$cachefile" ]; then
                rm -f "$cachefile" 2>/dev/null || true
            fi
        done
    fi
done

# Calculate final disk usage
FINAL_USAGE=$(df / | awk 'NR==2 {print $3}')
SAVED_SPACE=$((INITIAL_USAGE - FINAL_USAGE))

echo ""
echo "✅ Log cleanup completed!"
echo "📊 Disk space freed: $(format_bytes $((SAVED_SPACE * 1024)))"
echo "💾 Current disk usage: $(format_bytes $((FINAL_USAGE * 1024)))"
```

**Usage:** `drun add system/log-cleanup && drun system/log-cleanup`

---

## Service Monitoring

Monitor system services and processes.

```bash
#!/usr/bin/env bash
### DOC
# Monitor system services and resource usage
### DOC
set -euo pipefail

# Configuration
SERVICES_TO_MONITOR=(
    "docker"
    "nginx"
    "postgresql"
    "redis"
    "ssh"
)

CHECK_INTERVAL="${1:-10}"
MAX_CHECKS="${2:-6}"

echo "🔍 System Service Monitoring"
echo "============================"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "Max checks: $MAX_CHECKS"

# Function to check service status
check_service_status() {
    local service=$1

    if command -v systemctl > /dev/null 2>&1; then
        # systemd systems
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "✅ $service: Active"
        elif systemctl list-units --all | grep -q "$service"; then
            echo "❌ $service: Inactive"
        else
            echo "❓ $service: Not found"
        fi
    elif command -v service > /dev/null 2>&1; then
        # Traditional init systems
        if service "$service" status > /dev/null 2>&1; then
            echo "✅ $service: Running"
        else
            echo "❌ $service: Not running"
        fi
    else
        # Check if process is running
        if pgrep -f "$service" > /dev/null 2>&1; then
            echo "✅ $service: Running (process found)"
        else
            echo "❌ $service: Not running (no process found)"
        fi
    fi
}

# Function to show system resources
show_system_resources() {
    echo ""
    echo "💻 System Resources:"

    # CPU usage
    if command -v top > /dev/null 2>&1; then
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "N/A")
        echo "   CPU Usage: ${CPU_USAGE}%"
    fi

    # Memory usage
    if command -v free > /dev/null 2>&1; then
        MEMORY_INFO=$(free -h | awk 'NR==2{printf "Used: %s/%s (%.1f%%)", $3,$2,$3*100/$2}')
        echo "   Memory: $MEMORY_INFO"
    elif command -v vm_stat > /dev/null 2>&1; then
        # macOS
        VM_STAT=$(vm_stat | head -5 | tail -4)
        echo "   Memory: Available (use 'vm_stat' for details)"
    fi

    # Disk usage
    DISK_USAGE=$(df -h / | awk 'NR==2{printf "%s/%s (%s used)", $3,$2,$5}')
    echo "   Disk: $DISK_USAGE"

    # Load average
    if command -v uptime > /dev/null 2>&1; then
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
        echo "   Load Average:$LOAD_AVG"
    fi
}

# Function to show top processes
show_top_processes() {
    echo ""
    echo "🏃 Top Processes (by CPU):"

    if command -v ps > /dev/null 2>&1; then
        ps aux --sort=-%cpu | head -6 | tail -5 | \
        while IFS= read -r line; do
            echo "   $line"
        done
    fi
}

# Function to check network connections
check_network() {
    echo ""
    echo "🌐 Network Status:"

    # Check internet connectivity
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo "   ✅ Internet connectivity: OK"
    else
        echo "   ❌ Internet connectivity: Failed"
    fi

    # Show listening ports
    if command -v netstat > /dev/null 2>&1; then
        LISTENING_PORTS=$(netstat -ln | grep LISTEN | wc -l)
        echo "   🔌 Listening ports: $LISTENING_PORTS"
    elif command -v ss > /dev/null 2>&1; then
        LISTENING_PORTS=$(ss -ln | grep LISTEN | wc -l)
        echo "   🔌 Listening ports: $LISTENING_PORTS"
    fi
}

# Main monitoring loop
for ((i=1; i<=MAX_CHECKS; i++)); do
    clear
    echo "🔍 System Service Monitoring - Check $i/$MAX_CHECKS"
    echo "=================================================="
    echo "$(date)"

    # Check services
    echo ""
    echo "🔧 Service Status:"
    for service in "${SERVICES_TO_MONITOR[@]}"; do
        check_service_status "$service"
    done

    # Show system resources
    show_system_resources

    # Show top processes
    show_top_processes

    # Check network
    check_network

    # Check for alerts
    echo ""
    echo "⚠️  Alerts:"

    # High CPU alert
    if command -v top > /dev/null 2>&1; then
        HIGH_CPU_PROCS=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>80 {print $11}' | head -3)
        if [ -n "$HIGH_CPU_PROCS" ]; then
            echo "   🔥 High CPU processes detected"
        fi
    fi

    # High memory alert
    if command -v free > /dev/null 2>&1; then
        MEMORY_PERCENT=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [ "$MEMORY_PERCENT" -gt 85 ]; then
            echo "   🧠 High memory usage: ${MEMORY_PERCENT}%"
        fi
    fi

    # Disk space alert
    DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_PERCENT" -gt 85 ]; then
        echo "   💾 High disk usage: ${DISK_PERCENT}%"
    fi

    if [ "$i" -lt "$MAX_CHECKS" ]; then
        echo ""
        echo "Next check in ${CHECK_INTERVAL}s... (Press Ctrl+C to stop)"
        sleep "$CHECK_INTERVAL"
    fi
done

echo ""
echo "✅ Monitoring completed!"
```

**Usage:** `drun add system/monitor && drun system/monitor [interval] [max_checks]`

---

## Resource Usage Report

Generate detailed system resource usage report.

```bash
#!/usr/bin/env bash
### DOC
# Generate comprehensive system resource usage report
### DOC
set -euo pipefail

# Configuration
REPORT_FILE="${1:-$HOME/system-report-$(date +%Y%m%d_%H%M%S).txt}"
INCLUDE_PROCESSES="${2:-true}"

echo "📊 Generating System Resource Report"
echo "====================================="

# Start report
cat > "$REPORT_FILE" << EOF
System Resource Usage Report
Generated: $(date)
Hostname: $(hostname)
Uptime: $(uptime)

EOF

# System Information
echo "🖥️  Collecting system information..."
cat >> "$REPORT_FILE" << EOF
=== SYSTEM INFORMATION ===
OS: $(uname -a)
EOF

# Add distribution info if available
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribution: $PRETTY_NAME" >> "$REPORT_FILE"
elif command -v sw_vers > /dev/null 2>&1; then
    echo "Distribution: macOS $(sw_vers -productVersion)" >> "$REPORT_FILE"
fi

# CPU Information
echo "🔥 Collecting CPU information..."
cat >> "$REPORT_FILE" << EOF

=== CPU INFORMATION ===
EOF

if [ -f /proc/cpuinfo ]; then
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
    CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
    echo "Model: $CPU_MODEL" >> "$REPORT_FILE"
    echo "Cores: $CPU_CORES" >> "$REPORT_FILE"
elif command -v sysctl > /dev/null 2>&1; then
    # macOS
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
    echo "Model: $CPU_MODEL" >> "$REPORT_FILE"
    echo "Cores: $CPU_CORES" >> "$REPORT_FILE"
fi

# Memory Information
echo "🧠 Collecting memory information..."
cat >> "$REPORT_FILE" << EOF

=== MEMORY INFORMATION ===
EOF

if command -v free > /dev/null 2>&1; then
    free -h >> "$REPORT_FILE"
elif command -v vm_stat > /dev/null 2>&1; then
    # macOS
    vm_stat >> "$REPORT_FILE"
fi

# Disk Usage
echo "💾 Collecting disk usage..."
cat >> "$REPORT_FILE" << EOF

=== DISK USAGE ===
EOF

df -h >> "$REPORT_FILE"

# Top directories by size
echo "" >> "$REPORT_FILE"
echo "Largest directories in home:" >> "$REPORT_FILE"
du -h "$HOME" 2>/dev/null | sort -hr | head -10 >> "$REPORT_FILE" || true

# Network Information
echo "🌐 Collecting network information..."
cat >> "$REPORT_FILE" << EOF

=== NETWORK INFORMATION ===
EOF

# Network interfaces
if command -v ip > /dev/null 2>&1; then
    ip addr show >> "$REPORT_FILE"
elif command -v ifconfig > /dev/null 2>&1; then
    ifconfig >> "$REPORT_FILE"
fi

# Running Processes
if [ "$INCLUDE_PROCESSES" = "true" ]; then
    echo "🏃 Collecting process information..."
    cat >> "$REPORT_FILE" << EOF

=== RUNNING PROCESSES ===
Top processes by CPU:
EOF
    ps aux --sort=-%cpu | head -20 >> "$REPORT_FILE" 2>/dev/null || \
    ps aux | sort -k3 -nr | head -20 >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << EOF

Top processes by Memory:
EOF
    ps aux --sort=-%mem | head -20 >> "$REPORT_FILE" 2>/dev/null || \
    ps aux | sort -k4 -nr | head -20 >> "$REPORT_FILE"
fi

# System Services
echo "🔧 Collecting service information..."
cat >> "$REPORT_FILE" << EOF

=== SYSTEM SERVICES ===
EOF

if command -v systemctl > /dev/null 2>&1; then
    echo "Failed services:" >> "$REPORT_FILE"
    systemctl list-units --failed >> "$REPORT_FILE" 2>/dev/null || echo "None" >> "$REPORT_FILE"

    echo "" >> "$REPORT_FILE"
    echo "Active services (first 20):" >> "$REPORT_FILE"
    systemctl list-units --type=service --state=active | head -20 >> "$REPORT_FILE"
fi

# Environment Variables
echo "🌍 Collecting environment information..."
cat >> "$REPORT_FILE" << EOF

=== ENVIRONMENT ===
PATH: $PATH
SHELL: $SHELL
USER: $USER
HOME: $HOME
EOF

# Docker Information (if available)
if command -v docker > /dev/null 2>&1; then
    echo "🐋 Collecting Docker information..."
    cat >> "$REPORT_FILE" << EOF

=== DOCKER INFORMATION ===
EOF
    docker version >> "$REPORT_FILE" 2>/dev/null || echo "Docker not running" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" >> "$REPORT_FILE" 2>/dev/null || true
fi

# Git Configuration (if available)
if command -v git > /dev/null 2>&1; then
    echo "📝 Collecting Git information..."
    cat >> "$REPORT_FILE" << EOF

=== GIT CONFIGURATION ===
User: $(git config --global user.name 2>/dev/null || echo "Not set")
Email: $(git config --global user.email 2>/dev/null || echo "Not set")
EOF
fi

# Report completion
cat >> "$REPORT_FILE" << EOF

=== REPORT COMPLETED ===
Generated: $(date)
Report saved to: $REPORT_FILE
EOF

echo ""
echo "✅ System report generated successfully!"
echo "📄 Report saved to: $REPORT_FILE"
echo "📊 Report size: $(du -h "$REPORT_FILE" | cut -f1)"

# Display summary
echo ""
echo "📋 Quick Summary:"
echo "   Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F', load' '{print $1}')"
echo "   Disk usage: $(df / | awk 'NR==2{print $5}') used"
if command -v free > /dev/null 2>&1; then
    echo "   Memory usage: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
fi
```

**Usage:** `drun add system/report && drun system/report [output_file] [include_processes]`

---

## Automated System Updates

Automated system package updates with safety checks.

```bash
#!/usr/bin/env bash
### DOC
# Automated system updates with safety checks and rollback
### DOC
set -euo pipefail

# Configuration
DRY_RUN="${1:-false}"
AUTO_REBOOT="${2:-false}"
BACKUP_DIR="$HOME/update-backup-$(date +%Y%m%d_%H%M%S)"

echo "🔄 System Update Manager"
echo "======================="
echo "Dry run: $DRY_RUN"
echo "Auto reboot: $AUTO_REBOOT"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to detect package manager
detect_package_manager() {
    if command -v apt > /dev/null 2>&1; then
        echo "apt"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    elif command -v brew > /dev/null 2>&1; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function to backup important files
backup_system_files() {
    echo "💾 Creating system backup..."

    # Backup package lists
    if command -v dpkg > /dev/null 2>&1; then
        dpkg --get-selections > "$BACKUP_DIR/packages-dpkg.txt"
    fi

    if command -v rpm > /dev/null 2>&1; then
        rpm -qa > "$BACKUP_DIR/packages-rpm.txt"
    fi

    if command -v brew > /dev/null 2>&1; then
        brew list > "$BACKUP_DIR/packages-brew.txt"
    fi

    # Backup important config files
    for config in /etc/fstab /etc/hosts /etc/ssh/sshd_config; do
        if [ -f "$config" ]; then
            cp "$config" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done

    echo "   ✅ Backup created in $BACKUP_DIR"
}

# Function to check system health
check_system_health() {
    echo "🏥 Checking system health..."

    # Check disk space
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        echo "   ❌ Critical: Disk usage is ${DISK_USAGE}%"
        return 1
    else
        echo "   ✅ Disk usage: ${DISK_USAGE}%"
    fi

    # Check memory
    if command -v free > /dev/null 2>&1; then
        MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [ "$MEMORY_USAGE" -gt 95 ]; then
            echo "   ❌ Critical: Memory usage is ${MEMORY_USAGE}%"
            return 1
        else
            echo "   ✅ Memory usage: ${MEMORY_USAGE}%"
        fi
    fi

    # Check load average
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "   ℹ️  Load average: $LOAD_AVG"

    return 0
}

# Function to update packages
update_packages() {
    local pkg_manager=$1

    echo "📦 Updating packages with $pkg_manager..."

    if [ "$DRY_RUN" = "true" ]; then
        echo "   🔍 DRY RUN - would perform the following updates:"
    fi

    case $pkg_manager in
        apt)
            if [ "$DRY_RUN" = "true" ]; then
                apt list --upgradable
            else
                sudo apt update
                sudo apt upgrade -y
                sudo apt autoremove -y
                sudo apt autoclean
            fi
            ;;
        yum)
            if [ "$DRY_RUN" = "true" ]; then
                yum check-update
            else
                sudo yum update -y
                sudo yum autoremove -y
            fi
            ;;
        dnf)
            if [ "$DRY_RUN" = "true" ]; then
                dnf check-update
            else
                sudo dnf update -y
                sudo dnf autoremove -y
            fi
            ;;
        pacman)
            if [ "$DRY_RUN" = "true" ]; then
                pacman -Qu
            else
                sudo pacman -Syu --noconfirm
                sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
            fi
            ;;
        brew)
            if [ "$DRY_RUN" = "true" ]; then
                brew outdated
            else
                brew update
                brew upgrade
                brew cleanup
            fi
            ;;
        *)
            echo "   ❌ Unknown package manager"
            return 1
            ;;
    esac
}

# Function to check if reboot is needed
check_reboot_needed() {
    if [ -f /var/run/reboot-required ]; then
        return 0
    elif [ -f /tmp/.reboot-required ]; then
        return 0
    else
        # Check for kernel updates
        if command -v rpm > /dev/null 2>&1; then
            CURRENT_KERNEL=$(uname -r)
            LATEST_KERNEL=$(rpm -q kernel | tail -1 | sed 's/kernel-//')
            if [ "$CURRENT_KERNEL" != "$LATEST_KERNEL" ]; then
                return 0
            fi
        fi
        return 1
    fi
}

# Main update process
echo ""
backup_system_files

echo ""
if ! check_system_health; then
    echo "❌ System health check failed. Aborting updates."
    exit 1
fi

PKG_MANAGER=$(detect_package_manager)
echo ""
echo "📋 Detected package manager: $PKG_MANAGER"

if [ "$PKG_MANAGER" = "unknown" ]; then
    echo "❌ No supported package manager found"
    exit 1
fi

echo ""
update_packages "$PKG_MANAGER"

echo ""
echo "🔍 Post-update checks..."

# Check if reboot is needed
if check_reboot_needed; then
    echo "⚠️  System reboot is recommended"

    if [ "$AUTO_REBOOT" = "true" ]; then
        echo "🔄 Auto-reboot enabled. Rebooting in 10 seconds..."
        echo "   Press Ctrl+C to cancel"
        sleep 10
        sudo reboot
    else
        echo "💡 Run 'sudo reboot' when convenient"
    fi
else
    echo "✅ No reboot required"
fi

echo ""
echo "✅ System update completed!"
echo "📁 Backup saved to: $BACKUP_DIR"
echo "📊 Update log: /var/log/dpkg.log (Ubuntu/Debian) or /var/log/yum.log (RHEL/CentOS)"
```

**Usage:** `drun add system/update && drun system/update [dry_run] [auto_reboot]`
