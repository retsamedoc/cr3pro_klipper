#!/bin/bash
KLIPPER_PATH="${HOME}/klipper"
SYSTEMDDIR="/etc/systemd/system"

# Step 1:  Verify Klipper has been installed
check_klipper()
{
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "klipper.service")" ]; then
        echo "Klipper service found!"
    else
        echo "Klipper service not found, please install Klipper first"
        exit -1
    fi

}

# Step 2: Install startup script
install_script()
{
# Create systemd service file
    SERVICE_FILE="${SYSTEMDDIR}/klipper_config.service"
    [ -f $SERVICE_FILE ] && return
    echo "Installing system start script..."
    sudo /bin/sh -c "cat > ${SERVICE_FILE}" << EOF
[Unit]
Description=Dummy Service for klipper-config
After=klipper.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'exec -a klipper-config sleep 1'
[Install]
WantedBy=multi-user.target
EOF
# Use systemctl to enable the systemd service script
    sudo systemctl daemon-reload
    sudo systemctl enable klipper-config.service
}

# Step 3: restarting Klipper
restart_klipper()
{
    echo "Restarting Klipper..."
    sudo systemctl restart klipper
}

# Helper functions
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script must not run as root"
        exit -1
    fi
}

# Force script to exit if an error occurs
set -e

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"

# Parse command line arguments
while getopts "k:" arg; do
    case $arg in
        k) KLIPPER_PATH=$OPTARG;;
    esac
done

# Run steps
verify_ready
install_script
restart_klipper
