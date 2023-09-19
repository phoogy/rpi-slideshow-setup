#!/bin/bash

# Check if rclone is installed, and install it if not
if ! command -v rclone &>/dev/null; then
    curl https://rclone.org/install.sh | sudo bash
fi
