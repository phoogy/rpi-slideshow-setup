#!/bin/bash
SERVICE_FILENAME="slideshow.service"
SERVICE_PATH="/etc/systemd/system"
SERVICE_URL="https://github.com/phoogy/rpi-slideshow-setup/raw/main/slideshow.service"
SETUP_FILENAME="setup.sh"
SETUP_PATH="/usr/local/bin"
SETUP_URL="https://github.com/phoogy/rpi-slideshow-setup/raw/main/setup.sh"
RCLONE_URL="https://rclone.org/install.sh"
SOURCE_FOLDER="slideshow:"
DESTINATION_PATH="$HOME/slideshow"

# Function to sync and display images
sync_and_display() {
    rclone sync "$SOURCE_FOLDER" "$DESTINATION_PATH"
    sudo killall fbi
    sudo fbi -T 1 -t 30 -a --noverbose "$DESTINATION_PATH"/*
}

# Download the setup.sh file
if ! [ -f "$SETUP_PATH/$SETUP_FILENAME" ]; then
    echo "Downloading setup.sh"
    cd "$SETUP_PATH" && sudo curl -L -o "$SETUP_FILENAME" "$SETUP_URL" && sudo chmod +x setup.sh
fi

# Setup the slideshow.service
if ! [ -f "$SERVICE_PATH/$SERVICE_FILENAME" ]; then
    echo "Downloading slideshow.service"
    cd "$SERVICE_PATH"
    sudo curl -L -o "$SERVICE_FILENAME" "$SERVICE_URL"
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
    echo "You will need to run rclone config to setup config."
else

    # Last check before running
    if ! [ -f "$SETUP_PATH/$SETUP_FILENAME" ]; then
        echo "Setup file does not exist"
    elif ! [ -f "$SERVICE_PATH/$SERVICE_FILENAME" ]; then
        echo "Service file does not exist"
    elif ! command -v fbi &>/dev/null; then
        echo "rclone isnt installed"
    elif ! command -v fbi &>/dev/null; then
        echo "fbi not installed"
    elif ! [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        echo "rclone config has not been setup yet. please run rclone config"
    else
        # Initial synchronization and display
        echo "running initial sync_and_display"
        sync_and_display

        while true; do
            # Check for changes and sync every 1hr
            sleep 3600
            sync_and_display
        done
    fi
fi
