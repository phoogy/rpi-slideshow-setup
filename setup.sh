#!/bin/bash

# Check if rclone is installed, and install it if not
if ! command -v rclone &>/dev/null; then
    curl https://rclone.org/install.sh | sudo bash
fi

# Check if fbi is installed, and install it if not
if ! command -v fbi &>/dev/null; then
    sudo apt-get install -y fbi
fi