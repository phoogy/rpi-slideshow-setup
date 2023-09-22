#!/bin/bash

# Function to wait for internet
wait_for_internet() {
    while ! ping -c 1 google.com &>/dev/null; do
        echo "Waiting for internet connection..."
        sleep 5  # Adjust the interval as needed
    done
}

# Function to sync and display images
sync_and_display() {
    SOURCE_FOLDER="slideshow:"  # Replace with the actual source folder path
    DESTINATION_PATH="~/slideshow"
    rclone sync "$SOURCE_FOLDER" "$DESTINATION_PATH"

    # Display all image files in the destination path
    sudo fbi -T 1 -t 10 -a --noverbose "$DESTINATION_PATH"/*
}

# Check if fbi is installed, and install it if not
if ! command -v fbi &>/dev/null; then
    wait_for_internet
    sudo apt-get update
    sudo apt-get install -y fbi
fi

# Check if rclone is installed, and install it if not
if ! command -v rclone &>/dev/null; then
    wait_for_internet
    curl https://rclone.org/install.sh | sudo bash
fi

# Initial synchronization and display
sync_and_display

while true; do
    # Check for changes and sync every 1hr
    sleep 3600
    sync_and_display
done
