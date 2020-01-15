#!/bin/bash

#Edit the target device name before attempting to run the script
TARGET_DEVICE_NAME=""
BLUETOOTH_SERVICE_FILE="/lib/systemd/system/bluetooth.service"
SERVICE_KEY="ExecStart"
SERVICE_KEY_POST="ExecStartPost"
COMPATIBLE_MODE="/usr/lib/bluetooth/bluetoothd -C\nExecStartPost=/usr/bin/sdptool add SP \&\& hciconfig hci0 piscan"

if [[ -z $TARGET_DEVICE_NAME ]]; then
    echo "Please set the target device name to establish a connection"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please run the script as root"
    exit 1
fi

installLibs() {
    echo "Installing the bluetooth dev library"

    INSTALL_DEV_FAIL=0

    apt install libbluetooth-dev || INSTALL_DEV_FAIL=1

    if [[ $INSTALL_DEV_FAIL -eq 1 ]]; then
        echo "Failed to install dev tools for bluetooth"
        exit 1
    else
        echo "Successfully installed the bluetooth dev library"
    fi
}

setCompatibleFlag() {
    echo "Adding compatible mode flag (-C) to Bluetooth service"

    FLAG_FAIL=0
    sed -i "/^\($SERVICE_KEY_POST\)/d" $BLUETOOTH_SERVICE_FILE || FLAG_FAIL=1
    sed -i "s#^\($SERVICE_KEY\s*=\s*\).*#\1$COMPATIBLE_MODE#" $BLUETOOTH_SERVICE_FILE || FLAG_FAIL=1

    if [[ $FLAG_FAIL -eq 1 ]]; then 
        echo "Error occured while setting the compatible flag, check if you have the permissions to edit the file"
        exit 1
    else
        echo "Succesfully added the compatible flag"
    fi
}

restartBluetoothService() {
    echo "Restarting the bluetooth service"

    RESTART_FAIL=0

    systemctl restart bluetooth.service || RESTART_FAIL=1
    systemctl daemon-reload || RESTART_FAIL=1

    if [[ $RESTART_FAIL -eq 1 ]]; then
        echo "Error occured while restarting the bluetooth service"
        exit 1
    else
        echo "Successfully restarted the bluetooth service"
    fi
}

setupBluetooth() {
    echo "Setting up the bluetooth"
    BLUETOOTH_SETUP_FAIL=0

    hciconfig noauth || BLUETOOTH_SETUP_FAIL=1
    coproc BLUETOOTH_PROC (bluetoothctl -a) || BLUETOOTH_SETUP_FAIL=1
    echo -e 'power on\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    echo -e 'default-agent\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    echo -e 'discoverable on\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    echo -e 'pairable on\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    echo -e 'scan on\n' >&${BLUETOOTH_PROC[1]}
    sleep 10
    echo -e 'scan off\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    echo -e 'devices\n' >&${BLUETOOTH_PROC[1]}
    sleep 2
    IFS=' '
    echo 'Pair to "raspberrypi" from the target device'
    while read -ra output <&${BLUETOOTH_PROC[0]}; do
        if [[ ${output[2]} == $TARGET_DEVICE_NAME ]]; then
            echo "Found the target device with MAC address of ${output[1]}"
            echo "Pairing with the target device"
            echo -e "pair ${output[1]}\n" >&${BLUETOOTH_PROC[1]}
            sleep 10
            echo -e 'yes\n' >&${BLUETOOTH_PROC[1]}
            sleep 2
            echo -e "trust ${output[1]}\n" >&${BLUETOOTH_PROC[1]}
            sleep 2
            echo -e 'exit\n' >&${BLUETOOTH_PROC[1]}
        else
            echo "${output[@]}"
        fi
    done
    hciconfig hci0 piscan || BLUETOOTH_SETUP_FAIL=1
    sdptool add SP || BLUETOOTH_SETUP_FAIL=1

    if [[ $BLUETOOTH_SETUP_FAIL -eq 1 ]]; then
        echo "Error occured while restarting the bluetooth service"
        exit 1
    else
        echo "Successfully restarted the bluetooth service"
    fi
}

installLibs
setCompatibleFlag
restartBluetoothService
setupBluetooth

echo "Device is ready to communicate with serial over bluetooth"
