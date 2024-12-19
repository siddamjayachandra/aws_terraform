#!/bin/bash

# Log output
LOG_FILE="/var/log/user_data.log"
exec > $LOG_FILE 2>&1

echo "Starting user data script..."

# Wait for a few seconds to ensure volume attachment
echo "Waiting for volume attachment..."
ATTEMPTS=0
MAX_ATTEMPTS=30
VOLUME_ATTACHED=false

# Loop to check for volume attachment
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    # Check if the volume is attached by looking for device names like xvd[b-z]
    DEVICE_NAME=$(lsblk -o NAME,MOUNTPOINT | grep -E "xvd[b-z]" | awk '{print $1}' | head -n 1)
    
    if [ -n "$DEVICE_NAME" ]; then
        VOLUME_ATTACHED=true
        break
    fi

    # Wait for 10 seconds before checking again
    sleep 10
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "Waiting for volume attachment... Attempt $ATTEMPTS of $MAX_ATTEMPTS"
done

if [ "$VOLUME_ATTACHED" = false ]; then
    echo "EBS volume not attached after $MAX_ATTEMPTS attempts. Exiting script."
    exit 1
fi

echo "Volume attached. Continuing with the script..."

# Run e2fsck to check the file system for consistency on the root volume
echo "Running e2fsck on /dev/xvda1..."
sudo e2fsck -f /dev/xvda1

# Resize the partition for /dev/xvda
echo "Resizing partition on /dev/xvda..."
sudo growpart /dev/xvda 1

# Resize the file system on /dev/xvda1
echo "Resizing the file system on /dev/xvda1..."
sudo resize2fs /dev/xvda1

# Discover the dynamically attached EBS volume device name
echo "Discovering attached EBS volume..."
DEVICE_PATH="/dev/$DEVICE_NAME"

if [ -n "$DEVICE_NAME" ]; then
    echo "Volume $DEVICE_PATH found, formatting and mounting..."
    
    # Format the volume if it's not already formatted
    if ! sudo blkid $DEVICE_PATH | grep -q ext4; then
        echo "Formatting $DEVICE_PATH with ext4..."
        sudo mkfs.ext4 $DEVICE_PATH
    else
        echo "$DEVICE_PATH is already formatted with ext4."
    fi

    # Create mount point and mount the volume
    MOUNT_POINT="/mnt/$DEVICE_NAME"
    echo "Creating mount point at $MOUNT_POINT"
    sudo mkdir -p $MOUNT_POINT

    # Mount the device to the mount point
    echo "Mounting $DEVICE_PATH to $MOUNT_POINT"
    sudo mount $DEVICE_PATH $MOUNT_POINT

    # Ensure the volume is unmounted before running e2fsck
    echo "Checking if $MOUNT_POINT is mounted..."
    if mount | grep -q "$MOUNT_POINT"; then
        echo "Unmounting $MOUNT_POINT..."
        sudo umount $MOUNT_POINT
    else
        echo "$MOUNT_POINT is not mounted."
    fi

    # Run e2fsck with the -y option to automatically approve repairs
    echo "Running e2fsck on $DEVICE_PATH..."
    sudo e2fsck -f -y $DEVICE_PATH

    # Resize the file system on the newly detected device
    echo "Resizing the file system on $DEVICE_PATH..."
    sudo resize2fs $DEVICE_PATH

    # Mount the volume again
    echo "Mounting $DEVICE_PATH to $MOUNT_POINT..."
    sudo mount $DEVICE_PATH $MOUNT_POINT

    # Ensure it's mounted after reboot by updating /etc/fstab
    echo "$DEVICE_PATH $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
else
    echo "No additional EBS volume found. Exiting script."
    exit 1
fi

echo "User data script completed."
