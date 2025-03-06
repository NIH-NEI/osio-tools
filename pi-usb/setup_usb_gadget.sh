#!/bin/bash

cd /sys/kernel/config/usb_gadget/
mkdir -p pi_usb
cd pi_usb

echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "123456789" > strings/0x409/serialnumber
echo "Raspberry Pi" > strings/0x409/manufacturer
echo "Pi USB Drive" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1" > configs/c.1/strings/0x409/configuration
echo 120 > configs/c.1/MaxPower

mkdir -p functions/mass_storage.usb0
echo 1 > functions/mass_storage.usb0/sync
echo 0 > functions/mass_storage.usb0/removable
echo /usb-drive.img > functions/mass_storage.usb0/lun.0/file
ln -s functions/mass_storage.usb0 configs/c.1/

echo "name of UDC discovered earlier, eg. 1000480000.usb" > UDC
