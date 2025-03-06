# Raspberry Pi Virtual USB and SDS Upload Tool

This folder contains the scripts and instructions required to prepare a Raspberry Pi 5 to act as a virtual USB drive to the system it is connected to while also uploading its contents (along with a compressed log file), once per day.

## Preparation
For this device, you will need a Raspberry Pi 5 and, preferrably, a PoE+ HAT and case along with an appropriate USB-C cable.\
For Raspberry Pi 4 and 5, only the USB-C port can be configured for OTG, USB-A ports are host-only.\
This means it will need to connect to the instrument via the USB-C cable.\
If a PoE+ HAT is unavailable or not suitable, it is possible to power the device using a USB-C hub with pass-through power supply to the ports but it must be capable of passing through the required amperage (at least 4.5A).\
This is a less ideal solution as it is quite messy.

## Initial Configuration of the Pi
For general Pi setup, refer to online instructions of how to flash the OS onto a microSD card.\
You may install Raspberry Pi OS Lite or regular but the GUI is unneccessary.\
Enable SSH, give it an appropriate hostname, and check the IP settings using:
```
sudo nmtui
```
Be sure to make note of the IP address and MAC address.

## Enabling USB Gadget Mode
To set up the Raspberry Pi to act as a USB Mass Storage device, edit the boot configuration.\
Open the config.txt file with the command:
```
sudo nano /boot/firmware/config.txt
```
Add the following lines after [all] to enable USB gadget mode and allow greater flexibility for power supply (necessary when not using OEM power supply):
```
dtoverlay=dwc2
dr_mode=otg
usb_max_current_enable=1
```
To also ensure the Pi can boot from non-standard power supplies, run:
```
sudo -E rpi-eeprom-config –edit
```
Then add the line:
```
PSU_MAX_CURRENT=5000
```
You will also need to add a couple of lines to the modules file.
Run:
```
sudo nano /etc/modules
```
Just after the i2c-dev line, add:
```
dwc2
libcomposite
```
Now, you may reboot the Pi and run the following command to check if the USB controller is in peripheral mode:
```
ls /sys/class/udc
```
This should give you the name of the UDC device you will need for the “setup_usb_gadget.sh” script, **make note of it**.

## Create the Virtual USB Drive

To create the file that will be the virtual usb image, first decide what size the drive will need to be.\
Replacing the "count" value with the drive size in MB, run:
```
sudo dd if=/dev/zero of=/usb-drive.img bs=1M count=1024
```
This example would create a 1GB virtual USB drive.\
You can also adjust the block size, the bs value, if necessary.\
Format this new virtual drive with the command:
```
sudo mkfs.exfat /usb-drive.img
```
Mount the file to check its functionality:
```
sudo mkdir /mnt/usb
sudo mount /usb-drive.img /mnt/usb
sudo umount /mnt/usb
```

## Configure USB Gadget
Note: Before starting, check to see if the /sys/kernel/config/usb-gadget folder is missing and create it if it is not there.\
Create the gadget configuration script with the command:
```
sudo nano /usr/local/bin/setup_usb_gadget.sh
```
Copy and paste the contents of the setup_usb_gadget.sh script in this directory on GitHub but adjust the final line.\
For the last line, use the name of the UDC device you noted earlier, eg. 1000480000.usb.\
It might look like:
```
echo 1000480000.usb > UDC
```
Now make the script executable:
```
sudo chmod +x /usr/local/bin/setup_usb_gadget.sh
```
To make sure this script runs at boot, use systemd:\
Create a new service file for the script:
```
sudo nano /etc/systemd/system/usb_gadget.service
```
Define the Service Configuration by adding the following content to the file:
```
[Unit]
Description=USB Gadget Setup
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup_usb_gadget.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```
The fields in this file act as follows:
 - Description: A brief description of the service.
 - After=network.target: Ensures the service runs after the network stack is initialized (useful for some configurations).
 - ExecStart: Specifies the command to run your script.
 - Type=oneshot: Runs the script once and exits.
 - RemainAfterExit=true: Keeps the service active to ensure the USB gadget configuration persists.
 - WantedBy=multi-user.target: Ensures the service starts in the standard multi-user boot mode.
\
Use the following command to reload systemd to register the service:
```
sudo systemctl daemon-reload
```
Run the following command to enable the service to run at boot:
```
sudo systemctl enable usb_gadget.service
```
You can either reboot now or run the following command to start the service:
```
sudo systemctl start usb_gadget.service
```
Now, verify that the service is running and has executed your script:
```
sudo systemctl status usb_gadget.service
```
## Create Upload Script
Create a credentials file for the upload (repeat this step if password or username need to be updated/changed):
```
sudo nano /etc/smbcredentials
```
Add the credentails of the service account you will use to connect to the desired SDS location:
```
username="service_account_username"
password="service_account_password"
```
Secure the file:
```
sudo chmod 600 /etc/smbcredentials
```
Install the necessary tools:
```
sudo apt update
sudo apt install cifs-utils
```
Now, create the upload script file:
```
sudo nano /usr/bin/upload_data.sh
```
Copy and paste the contents of the upload_data.sh script in this directory on GitHub making sure to adjust the variable "SMB_SHARE" to match the SDS destination desired.\
Make it executable with the command:
```
sudo chmod +x /usr/bin/upload_data.sh
```
In the current state, this script will:
 - Create a timestamped folder in the destination folder (specified by SMB_SHARE variable).
 - Upload the contents of the virtual USB drive to the timestamped folder, excluding "System Volume Information" folder.
 - (Optional, currently commented out) Perform secondary file integrity verification (rsync already performs integrity check).
 - Deletes files from USB image as integrity of copy is confirmed.
 - Uploads a compressed .tar.gz file of the log to the same folder.
 - Clears log file (can be commented out if desired but will continue to grow).
 - Unbind and rebind USB gadget to cleare cached files in Windows (otherwise will deleted files will remain and be uploaded again next time).
## Schedule Upload with Cron
Open the crontab editor:
```
sudo crontab -e
```
Add the following line to run the upload script daily at 2 AM (adjust the time as needed):
```
0 2 * * * /usr/bin/upload_data.sh
```
## Test the Setup
Reboot the Raspberry Pi and check if it appears as a USB drive when connected to a computer.\
Run the upload script manually with the following command:
```
sudo /usr/bin/upload_data.sh
```
Verify that the cron job runs as expected and uploads the data and log to the network location in correctly timestamped folders.

Check error logs for USB errors with command:
```
“dmesg | grep usb”
```
You can also check the upload log with the command:
```
cat /var/log/upload_data.log
```
