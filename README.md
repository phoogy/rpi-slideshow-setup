# rpi-slideshow-setup
1. Image pi with wifi network connection details
2. Connect pi to monitor via HDMI
3. Connect pi to power
4. SSH into pi
5. run `curl "https://raw.githubusercontent.com/phoogy/rpi-slideshow-setup/main/setup.sh" | bash`
6. After it finishes run `rclone config`
    - Remote Folder should be named `slideshow` for the config
7. Restart pi
