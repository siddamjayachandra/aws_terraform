#!/bin/bash

# Wait for a few seconds to ensure volume attachment
echo "Waiting for volume attachment..."
sleep 30

# Log output
LOG_FILE="/var/log/user_data.log"
exec > $LOG_FILE 2>&1

echo "Starting user data script..."

# Check if the volume is available
if lsblk | grep -q xvdf; then
    echo "Volume /dev/xvdf found, formatting and mounting..."
    
    # Format the volume if it's not already formatted
    if ! sudo blkid /dev/xvdf | grep -q ext4; then
        echo "Formatting /dev/xvdf with ext4..."
        sudo mkfs.ext4 /dev/xvdf
    else
        echo "/dev/xvdf is already formatted with ext4."
    fi

    # Create mount point and mount the volume
    MOUNT_POINT="/mnt/xvdf"
    sudo mkdir -p $MOUNT_POINT
    sudo mount /dev/xvdf $MOUNT_POINT

    # Ensure it's mounted after reboot by updating /etc/fstab
    echo "/dev/xvdf $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
else
    echo "Volume /dev/xvdf not found. Exiting script."
    exit 1
fi

echo "User data script completed."
