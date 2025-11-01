#!/usr/bin/env bash
#
# fix-bluetooth.sh - Fix Bluetooth on MacBook Pro running Ubuntu
#
# This script addresses the common issue where the Bluetooth controller
# (Broadcom UART device) fails to initialize properly on MacBook Pro
# hardware running Ubuntu Linux.
#
# The root cause on MacBook Pro is that the Broadcom UART device (BCM4350)
# hangs with command timeouts (error -110) during initialization. This happens
# because the device lacks proper ACPI GPIO resources and the UART initialization
# fails at the kernel driver level.
#
# Unfortunately, at the current state of macOS/Linux bluetooth support on
# MacBook Pro, this is a hardware/firmware limitation that cannot be fully
# resolved in userspace. The script makes a best-effort attempt to recover
# the device, but a full system restart or workarounds may be needed.

set -eu -o pipefail

echo "Fixing Bluetooth on MacBook Pro..."
echo ""
echo "NOTE: Bluetooth timeouts on MacBook Pro are a known limitation."
echo "If this fails, try: reboot, or run: sudo systemctl restart bluetooth"
echo ""

# Stop the Bluetooth service
echo "Stopping Bluetooth service..."
sudo systemctl stop bluetooth

# Give it time to fully stop
sleep 2

# Unbind the Broadcom UART device from the driver completely
# This allows the next binding attempt to reinitialize from scratch
echo "Unbinding Broadcom UART device from driver..."
for uart_device in /sys/bus/serial/devices/serial*; do
    if [ -d "$uart_device" ]; then
        device_name=$(basename "$uart_device")
        # Try to unbind from hci_uart driver
        if [ -L "$uart_device/driver" ]; then
            echo "  Unbinding $device_name"
            echo "$device_name" | sudo tee /sys/bus/serial/drivers/hci_uart_bcm/unbind 2>/dev/null || \
            echo "$device_name" | sudo tee /sys/bus/serial/drivers/hci_uart/unbind 2>/dev/null || true
        fi
    fi
done

sleep 2

# Force reload of all Bluetooth-related modules
# Remove in order: dependent modules first
echo "Removing Bluetooth kernel modules..."
for module in bnep rfcomm sco l2cap cdc_acm hci_uart btbcm btintel btqca btmtk btrtl btusb bluetooth; do
    if lsmod | grep -q "^$module"; then
        echo "  Removing $module"
        sudo modprobe -r "$module" 2>/dev/null || true
    fi
done

sleep 2

# Reload modules in dependency order
echo "Reloading Bluetooth kernel modules..."
sudo modprobe bluetooth
sleep 1
sudo modprobe hci_uart
sleep 1
sudo modprobe btbcm
sleep 1

# Start the Bluetooth service
echo "Starting Bluetooth service..."
sudo systemctl start bluetooth

# Give more time for UART device to initialize
# On MacBook Pro, UART initialization is slow and may timeout
sleep 5

# Check the status
echo ""
echo "Checking Bluetooth status..."
if hciconfig -a 2>/dev/null | grep -q "UP RUNNING"; then
    echo "✓ SUCCESS: Bluetooth controller is UP and RUNNING"
    hciconfig -a
    echo ""
    echo "✓ Bluetooth is working! You can use bluetoothctl to manage devices."
else
    # Check if device at least exists
    if hciconfig 2>/dev/null | grep -q "hci0"; then
        echo "⚠ PARTIAL: Bluetooth device exists but is not UP"
        echo ""
        echo "Device status:"
        hciconfig -a
        echo ""
        echo "The device may still be initializing. Attempting to bring it up..."

        # Try to manually bring up the device
        if timeout 10 sudo hciconfig hci0 up 2>/dev/null; then
            sleep 2
            if hciconfig -a 2>/dev/null | grep -q "UP RUNNING"; then
                echo "✓ Device is now UP and RUNNING"
                echo "✓ Bluetooth is now working!"
                exit 0
            fi
        fi

        echo "⚠ Device still not responding. This is a known MacBook Pro limitation."
        echo ""
    else
        echo "✗ FAILED: Bluetooth device not found"
        echo ""
        echo "This is a critical issue - the UART device is completely unresponsive."
        echo "The kernel logs show timeout errors (error -110), indicating the"
        echo "Broadcom controller is not responding to initialization commands."
        echo ""
    fi

    echo "Next steps:"
    echo "  1. Restart your system: sudo reboot"
    echo "  2. If bluetooth still doesn't work after reboot, the hardware may be"
    echo "     disconnected or in a bad state - try a hard reset (shut down, wait 30s, power on)"
    echo "  3. Check kernel logs: sudo journalctl -u bluetooth -n 50"
    echo "  4. Check dmesg: sudo dmesg | grep -i bluetooth | tail -20"
    exit 1
fi
