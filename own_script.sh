#!/bin/bash
# Log output
LOG_FILE="/home/ec2-user/user_data.log"
touch $LOG_FILE 


VOLUME_ATTACHED=$(lsblk -o NAME,MOUNTPOINT | grep -E "xvd[b-z]" | awk '{print $1}' | head -n 1)
echo "VOlument attached: $VOLUME_ATTACHED" >> $LOG_FILE
    if [ -e "$VOLUME_ATTACHED" ]; then
    echo "No ebs volume atached!" >> $LOG_FILE
        exit 1
    fi

    DF_OUTPUT=$(df -h  | grep -E "xvd[b-z]"   | awk '{print $1}' | head -n 1)

    echo "Df out put: $DF_OUTPUT" >> $LOG_FILE
    if [ -n "$DF_OUTPUT" ]; then
    echo "Already mounted" >> $LOG_FILE
    echo "Check for sizes" >> $LOG_FILE
   CS=$(lsblk -o NAME,SIZE | grep -E "xvd[b-z]" | awk '{print $2}' | head -n 1)
   DS=$(df -h  | grep -E "xvd[b-z]"   | awk '{print $4}' | head -n 1)
   DS="${DS//[[:alpha:]]/}"
   CS="${CS//[[:alpha:]]/}"
   if (( $(echo "$CS > $DS" | bc -l) )); then
           MOUNT_POINT="/mnt/${VOLUME_ATTACHED}"
           sudo umount $MOUNT_POINT >> $LOG_FILE

    echo "Running e2fsck on $DEVICE_PATH..."  >> $LOG_FILE
    sudo e2fsck -f -y "/dev/${VOLUME_ATTACHED}"  >> $LOG_FILE 

    sudo resize2fs "/dev/${VOLUME_ATTACHED}" >> $LOG_FILE

    # Mount the volume again
    sudo mount "/dev/${VOLUME_ATTACHED}"  $MOUNT_POINT  >> $LOG_FILE
     fi


else
            echo "Still not mounted.. " >> $LOG_FILE
    echo "Formatting $DF_OUTPUT with ext4..." >> $LOG_FILE
     sudo mkfs.ext4 "/dev/${VOLUME_ATTACHED}" >> $LOG_FILE
    MOUNT_POINT="/mnt/${VOLUME_ATTACHED}"  
    echo "showing mount: $MOUNT_POINT"  >> $LOG_FILE
    sudo mkdir -p $MOUNT_POINT 
    sudo mount "/dev/${VOLUME_ATTACHED}"  $MOUNT_POINT >> $LOG_FILE

    fi