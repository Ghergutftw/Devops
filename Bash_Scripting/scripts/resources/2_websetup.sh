#!/bin/bash
set -euo pipefail

# Variables
ARTIFACT_URL="https://www.tooplate.com/zip-templates/2098_health.zip"
TMP_DIR="/tmp/webfiles"
WEB_ROOT="/var/www/html"
ZIP_FILE="$TMP_DIR/2098_health.zip"


# Functions
log() {
    echo -e "\n########################################"
    echo "$1"
    echo "########################################"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Try 'sudo $0'"
        exit 1
    fi
}

install_packages() {
    log "Installing packages"
    yum install -y wget unzip httpd > /dev/null
}

start_httpd() {
    log "Start & Enable HTTPD Service"
    systemctl enable --now httpd
}

deploy_artifact() {
    log "Starting Artifact Deployment"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    wget -q "$ARTIFACT_URL" -O "$ZIP_FILE"
    unzip -q "$ZIP_FILE"
    cp -r 2098_health/* "$WEB_ROOT/"
}

restart_httpd() {
    log "Restarting HTTPD service"
    systemctl restart httpd
}

cleanup() {
    log "Removing Temporary Files"
    rm -rf "$TMP_DIR"
}

show_status() {
    systemctl status httpd --no-pager
    ls -l "$WEB_ROOT"
}

# Main script execution
check_root
install_packages
start_httpd
deploy_artifact
restart_httpd
cleanup
show_status