# Raspberry Pi Virtual USB and SDS Upload Tool

This folder contains the scripts and instructions required to prepare a Raspberry Pi 5 to act as a virtual USB drive to the system it is connected to while also uploading (and clearing) its contents once per day.

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
The fields in this file act as follows:\
Description: A brief description of the service.\
After=network.target: Ensures the service runs after the network stack is initialized (useful for some configurations).\
ExecStart: Specifies the command to run your script.\
Type=oneshot: Runs the script once and exits.\
RemainAfterExit=true: Keeps the service active to ensure the USB gadget configuration persists.\
WantedBy=multi-user.target: Ensures the service starts in the standard multi-user boot mode.\
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
Add:
```
username=your_username
password=your_password
```
Secure the file:
```
sudo chmod 600 /etc/smbcredentials
```



## Schedule Upload with Cron



The `bootstrap.sh` script will configure a MacOS system for scientific benchmark tests by configuring python, homebrew, installing ansible (via system python) and running the playbook [initial-config.yml](initial-config.yml)
It installs the following:
- homebrew
- Java (OpenJDK 11)
- nextflow (>=23.10)

On a fresh or factory reset computer, create the user account, connect to the internet, then run the following to install Mac Developer tools:

```
xcode-select --install
```

Now, we can clone the osio-tools repository and run the 'bootstrap' script.
Note that this script will prompt you for the system password to install homebrew, then again for ansible. This should install all the dependencies.

```bash
git clone https://github.com/NIH-NEI/osio-tools.git
cd osio-tools
./scibench/bootstrap.sh
# <enter password>
# <enter password for ansible>
```

Note, you will have to manually install/configure Docker, that is not functioning automatically.

## Running benchmarks
**Start a new shell** to source all the environment variables created by the ansible playbook.

This step also requires an internet connection to download the nextflow pipelines and data for other benchmarks.


```
./scibench/runall.sh
```
this is a driver script that will run:
- nextflow sarek benchmark
- sysbench benchmarks
- Scientific python benchmarks for image processing and ML

## Results

TODO(nick) Results will be:

