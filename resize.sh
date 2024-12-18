#!/bin/bash
# Run e2fsck to check the file system for consistency
sudo e2fsck -f /dev/xvda1
growpart /dev/xvda 1
# Resize the file system to use the new volume size
sudo resize2fs /dev/xvda1