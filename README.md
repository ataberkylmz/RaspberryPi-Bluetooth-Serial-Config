# Automated Bluetooth Serial Configuration for Pi

Automated shell script for configuring the internal Bluetooth of the Raspberry Pi to communicate with Serial. This script does not provide any RFCOMM server, if you are looking for a server, I'd suggest using [Pybluez Library](https://github.com/pybluez/pybluez) if your intention is to use Python, you can always use [bluetooth-serial-port](https://github.com/eelcocramer/node-bluetooth-serial-port) with Node/JavaScript.

# Usage

Set the `TARGET_DEVICE_NAME` to the name of the device that you are going to pair and run with superuser privileges. This helps the script to find the MAC address of the device and pair with it. Otherwise the script will not work.

## Issues

- ~~-Running the script multiple times inserts empty new lines after `ExecStartPost` key in
 `/lib/systemd/system/bluetooth.service`. You can manually edit the file to get rid of those new lines afterwards as a work around for now.~~
 - Script does not have any functionality to check if the device is already paired or not. Running the script multiple times might cause unexpected Bluetooth behavior.

