#!/bin/bash
SERVICE_FILENAME="slideshow.service"
SERVICE_PATH="/etc/systemd/system"
SERVICE_URL="https://raw.githubusercontent.com/phoogy/rpi-slideshow-setup/develop/slideshow.service"
SETUP_FILENAME="setup.sh"
SETUP_PATH="/usr/local/bin"
SETUP_URL="https://raw.githubusercontent.com/phoogy/rpi-slideshow-setup/develop/setup.sh"
RCLONE_URL="https://rclone.org/install.sh"
SOURCE_FOLDER="slideshow:"
DESTINATION_PATH="$HOME/slideshow"
SLIDESHOW_DELAY=3

flag_file="/var/tmp/apt-get-update-flag"

# Function to clean up on exit
cleanup() {
    rm -f "$flag_file"
}
trap cleanup EXIT

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
    if [ ! -f "$flag_file" ]
    then
        sudo apt-get update && touch "$flag_file"
    fi
    sudo apt-get install -y fbi
fi

# Check if inotify-tools is installed, and install if not
if ! command -v inotifywait &>/dev/null; then
    echo "Downloading inotify-tools"
    if [ ! -f "$flag_file" ]
    then
        sudo apt-get update && touch "$flag_file"
    fi
    sudo apt-get install -y inotify-tools
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
    elif ! command -v rclone &>/dev/null; then
        echo "rclone isnt installed"
    elif ! command -v fbi &>/dev/null; then
        echo "fbi not installed"
    elif ! [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        echo "rclone config has not been setup yet. please run rclone config if it wasnt run"
    else
        echo "Starting the slideshow..."
        
        # Check if lock file exists
        if [ -f /tmp/rclone_sync.lock ]; then
            echo "Lock file exists, script is already running"
            exit 1
        fi

        # Create a lock file
        exec 200>/tmp/rclone_sync.lock

        # Start a background process for syncing
        SYNC_PID=
        (
            
            while true; do
                # Try to acquire the lock and run the sync
                flock -n 200 rclone sync "$SOURCE_FOLDER" "$DESTINATION_PATH"

                # Check for changes and sync every 1 min
                sleep 60
            done
        ) & SYNC_PID=$!

        REBOOT_PID=
        (

            while true; do
                # Sleep for 1 hour
                sleep 3600

                # Get the current hour
                CURRENT_HOUR=$(date +%H)

                # Reboot the system at midnight
                if [ "$CURRENT_HOUR" -eq 00 ]; then
                    sudo reboot
                fi
            done
        ) & REBOOT_PID=$!

        FBI_PID=
        (
            # Check if the directory does not exist
            if [ ! -d "$DESTINATION_PATH/slideshow" ]; then
                # Create the directory
                mkdir -p "$DESTINATION_PATH/slideshow"
            fi

            sudo killall fbi
            sudo fbi -T 1 -t 10 -a --noverbose "$DESTINATION_PATH"/*

            # Monitor the directory for new files, deletions, and modifications
            inotifywait -m -e create -e moved_to -e delete -e modify "$DESTINATION_PATH" | while read path action file; do
                echo "Detected event: $file, action: $action"
                if [[ "$file" =~ .*\.(jpg|jpeg|png|gif)$ ]]; then
                    echo "Restarting with new images..."
                    sudo killall fbi
                    sudo fbi -T 1 -t "$SLIDESHOW_DELAY" -a --noverbose "$DESTINATION_PATH"/*
                fi
            done

        ) & FBI_PID=$!

        
        # Set a trap to stop the sync process and remove the lock file when the script is terminated
        trap "kill $SYNC_PID; kill $REBOOT_PID; kill $FBI_PID; rm -f /tmp/rclone_sync.lock; sudo killall fbi" EXIT


        #loop to keep script running
        while true; do
            sleep 1
        done
        
    fi
fi
