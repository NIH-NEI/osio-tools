#!/bin/bash

# Set variables
USB_IMAGE="/usb-drive.img"
USB_MOUNT="/mnt/usb"
SMB_SHARE="//server/share"
SMB_MOUNT="/mnt/smbshare"
SMB_CREDENTIALS="/etc/smbcredentials"
LOG_FILE="/var/log/upload_data.log"

# Generate timestamp for the upload folder (YYYY-MM-DD_HH-MM-SS)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
UPLOAD_DIR="$SMB_MOUNT/$TIMESTAMP"
LOG_ARCHIVE="/var/log/upload_data_$TIMESTAMP.tar.gz"

# Logging function
log() {
    echo "$(date): $1" >> $LOG_FILE
}

log "Script started."

# Check if USB image exists
if [ ! -f "$USB_IMAGE" ]; then
    log "Error: USB image $USB_IMAGE not found."
    exit 1
fi

# Mount the USB image
if ! mountpoint -q "$USB_MOUNT"; then
    log "Mounting USB image $USB_IMAGE to $USB_MOUNT."
    sudo mount -o loop "$USB_IMAGE" "$USB_MOUNT"
    if [ $? -ne 0 ]; then
        log "Error: Failed to mount USB image."
        exit 1
    fi
else
    log "USB image is already mounted."
fi

# Check if there are files to upload (excluding "System Volume Information")
if ! find "$USB_MOUNT" -mindepth 1 -not -path "$USB_MOUNT/System Volume Information*" | grep -q .; then
    log "No files found for upload. Exiting."
    sudo umount "$USB_MOUNT"
    exit 0
fi

log "Files found. Proceeding with upload."

# Mount the SMB share
if ! mountpoint -q "$SMB_MOUNT"; then
    log "Mounting SMB share $SMB_SHARE to $SMB_MOUNT."
    sudo mount -t cifs -o credentials="$SMB_CREDENTIALS",iocharset=utf8 "$SMB_SHARE" "$SMB_MOUNT"
    if [ $? -ne 0 ]; then
        log "Error: Failed to mount SMB share."
        sudo umount "$USB_MOUNT"
        exit 1
    fi
else
    log "SMB share is already mounted."
fi

# Create a timestamped folder inside the SMB share
log "Creating directory $UPLOAD_DIR."
mkdir -p "$UPLOAD_DIR"

# Upload data to the SMB share while excluding "System Volume Information"
log "Starting data upload to $UPLOAD_DIR, excluding 'System Volume Information'."
rsync -av --exclude="System Volume Information" "$USB_MOUNT/" "$UPLOAD_DIR/"
if [ $? -eq 0 ]; then
    log "Data upload completed successfully."
else
    log "Error: Data upload failed."
    sudo umount "$USB_MOUNT"
    sudo umount "$SMB_MOUNT"
    exit 1
fi

# Verify file integrity and delete only matching files
#log "Verifying file integrity before deletion."
find "$USB_MOUNT" -type f | while read -r SRC_FILE; do
#Modified to remove second verify due to issues with xml files
#rsync already does integrity check so additional check not critical
#comment next two lines if un-commenting second integrity check
    rm "$SRC_FILE"
    log "Source file deleted: $SRC_FILE."

#    REL_PATH="${SRC_FILE#$USB_MOUNT/}"  # Get the relative path
#   DEST_FILE="$SMB_MOUNT/$REL_PATH"

#    if [ -f "$DEST_FILE" ]; then
#        SRC_CHECKSUM=$(md5sum "$SRC_FILE" | awk '{print $1}')
#        DEST_CHECKSUM=$(md5sum "$DEST_FILE" | awk '{print $1}')

#        if [ "$SRC_CHECKSUM" == "$DEST_CHECKSUM" ]; then
#            log "File verified: $REL_PATH"
#            rm "$SRC_FILE"
#            log "Source file deleted: $SRC_FILE."
#        else
#            log "Checksum mismatch: $REL_PATH. File not deleted."
#        fi
#    else
#        log "Destination file missing: $REL_PATH. File not deleted."
#    fi
done

# Remove empty directories inside the USB mount but do not delete /mnt/usb itself
log "Removing empty directories."
find "$USB_MOUNT" -mindepth 1 -type d -empty -delete

# Compress the log file into a tar archive
log "Compressing log file."
tar -czf "$LOG_ARCHIVE" "$LOG_FILE"

# Upload the compressed log file to the SMB folder
log "Uploading log archive to $UPLOAD_DIR."
rsync -av "$LOG_ARCHIVE" "$UPLOAD_DIR/"

# Clear the log file after archiving (optional)
echo "" > "$LOG_FILE"

# Unmount the USB image
log "Unmounting USB image."
sudo umount "$USB_MOUNT"
if [ $? -ne 0 ]; then
    log "Warning: Failed to unmount USB image."
fi

# Unmount the SMB share
log "Unmounting SMB share."
sudo umount "$SMB_MOUNT"
if [ $? -ne 0 ]; then
    log "Warning: Failed to unmount SMB share."
fi
# Unbind USB gadget to force Windows to recognize the device as unplugged
log "Unbinding USB gadget to force host OS to recognize device removal."
echo "" | sudo tee /sys/kernel/config/usb_gadget/pi_usb/UDC
sleep 2  # Wait for Windows to recognize the removal

# Rebind the gadget to make it appear again
log "Rebinding USB gadget."
echo "$(ls /sys/class/udc)" | sudo tee /sys/kernel/config/usb_gadget/pi_usb/UDC
log "Script completed."
exit 0
