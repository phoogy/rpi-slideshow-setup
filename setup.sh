#!/bin/bash

SERVICE_PATH="/etc/systemd/system/slideshow.service"
SERVICE_URL="https://github.com/phoogy/rpi-slideshow-setup/raw/main/slideshow.service"
SETUP_PATH="~/setup.sh"
SETUP_URL="https://github.com/phoogy/rpi-slideshow-setup/raw/main/setup.sh"
RCLONE_URL="https://rclone.org/install.sh"
SOURCE_FOLDER="slideshow:"
DESTINATION_PATH="~/slideshow"

# Function to sync and display images
sync_and_display() {
    rclone sync "$SOURCE_FOLDER" "$DESTINATION_PATH"
    sudo killall fbi
    sudo fbi -T 1 -t 30 -a --noverbose "$DESTINATION_PATH"/*
}

# Download the setup.sh file
if ! [ -f "$SETUP_PATH" ]; then
    echo "Downloading setup.sh"
    curl -o "$SETUP_PATH" "$SETUP_URL"
fi

# Setup the slideshow.service
if ! [ -f "$SERVICE_PATH" ]; then
    echo "Downloading slideshow.service"
    sudo curl -o "$SERVICE_PATH" "$SETUP_URL"
    echo "Setting up systemctl slideshow.service"
    sudo systemctl daemon-reload
    sudo systemctl enable slideshow.service
    sudo systemctl start slideshow.service
fi

# Check if fbi is installed, and install it if not
if ! command -v fbi &>/dev/null; then
    echo "Downloading fbi"
    sudo apt-get update
    sudo apt-get install -y fbi
fi

# Check if rclone is installed, and install it if not
if ! command -v rclone &>/dev/null; then
    echo "Downloading rclone"
    curl "$RCLONE_URL" | sudo bash
    echo "Automatic setup part done."
    echo "You will need to run rclone config to fix config. See google doc for more details."
    echo "Don't forget to change the wifi if you haven't already!"
else
    # Initial synchronization and display
    sync_and_display

    while true; do
        # Check for changes and sync every 1hr
        sleep 3600
        sync_and_display
    done
fi
