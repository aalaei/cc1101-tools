#!/bin/bash

# === CONFIGURATION ===
ESP8266_IP="cc1101-tools.local"
ESP8266_PORT="23"
VIRTUAL_PORT="/tmp/esp8266telnet"
PID_FILE="/tmp/esp8266_socat.pid"

# === CLEANUP FUNCTION ===
cleanup() {
    echo -e "\n[+] Cleaning up..."

    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "[*] Killing socat (PID $PID)..."
        kill "$PID" 2>/dev/null
        rm -f "$PID_FILE"
    fi

    if [ -e "$VIRTUAL_PORT" ]; then
        echo "[*] Removing virtual port $VIRTUAL_PORT"
        rm -f "$VIRTUAL_PORT"
    fi

    echo "[+] Done. Exiting."
    exit 0
}

# === CTRL+C HANDLER ===
trap cleanup INT

# === START SOCAT (quiet) ===
echo "[+] Starting socat silently..."
socat TCP:$ESP8266_IP:$ESP8266_PORT PTY,link=$VIRTUAL_PORT,echo=0,rawer &> /dev/null &

SOCAT_PID=$!
echo $SOCAT_PID > "$PID_FILE"

# Wait a bit for the PTY to appear
sleep 0.5

if [ ! -e "$VIRTUAL_PORT" ]; then
    echo "[!] Failed to create virtual port."
    cleanup
fi

echo "[+] Virtual port created: $VIRTUAL_PORT"
echo "[+] Opening terminal. Press Ctrl+C to exit and clean up."
# === START TERMINAL CLIENT (screen) ===
picocom -b 115200 "$VIRTUAL_PORT"
# === AFTER SCREEN EXIT, CLEANUP ===
cleanup

