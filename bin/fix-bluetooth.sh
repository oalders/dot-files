#!/usr/bin/env bash
#
# fix-bluetooth.sh - Fix Bluetooth on MacBook Pro running Ubuntu
#
# This script addresses the common issue where the Bluetooth controller
# (Broadcom UART device) fails to initialize properly on MacBook Pro
# hardware running Ubuntu Linux.
#
# The fix involves stopping the Bluetooth service, reloading the kernel
# modules, and restarting the service to properly initialize the device.

set -eu -o pipefail

echo "Fixing Bluetooth on MacBook Pro..."

# Stop the Bluetooth service
echo "Stopping Bluetooth service..."
sudo systemctl stop bluetooth

# Give it a moment to fully stop
sleep 1

# Reload the Bluetooth kernel modules
# Note: We ignore errors if modules are already unloaded
echo "Reloading Bluetooth kernel modules..."
sudo modprobe -r bnep bluetooth btbcm btintel btqca btmtk btrtl btusb hci_uart 2>/dev/null || true

sleep 2

# Load the modules back
sudo modprobe bluetooth
sudo modprobe hci_uart
sudo modprobe btbcm

# Start the Bluetooth service
echo "Starting Bluetooth service..."
sudo systemctl start bluetooth

# Give it time to initialize
sleep 3

# Check the status
echo ""
echo "Bluetooth status:"
if hciconfig -a 2>/dev/null | grep -q "UP RUNNING"; then
    echo "✓ Bluetooth controller is UP and RUNNING"
    hciconfig -a
    echo ""
    echo "✓ Bluetooth is now working! You can use bluetoothctl to manage devices."
else
    echo "✗ Bluetooth controller may not have initialized properly."
    echo "Current status:"
    hciconfig -a 2>/dev/null || echo "No HCI devices found"
    exit 1
fi
