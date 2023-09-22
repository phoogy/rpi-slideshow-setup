#!/bin/bash
wait_for_internet() {
    while ! ping -c 1 google.com &>/dev/null; do
        echo "Waiting for internet connection..."
        sleep 5  # Adjust the interval as needed
    done
}

# Check if rclone is installed, and install it if not
if ! command -v rclone &>/dev/null; then
    curl https://rclone.org/install.sh | sudo bash
fi

# Check if fbi is installed, and install it if not
if ! command -v fbi &>/dev/null; then
    sudo apt-get install -y fbi
fi