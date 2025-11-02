#!/bin/bash

#─────────────────────────────────────────────
# Multi-domain Nginx + Certbot Auto Setup
#─────────────────────────────────────────────
# Author: Mark Chisholm
# Description: Automatically sets up Nginx and HTTPS for multiple domains
#─────────────────────────────────────────────

set -e  # Exit on error

#─────────────────────────────────────────────
# Color Setup
#─────────────────────────────────────────────
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

info()    { echo -e "${CYAN}➜${RESET} $1"; }
success() { echo -e "${GREEN}✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
error()   { echo -e "${RED}✖${RESET} $1" >&2; }

#─────────────────────────────────────────────
# Helper Functions
#─────────────────────────────────────────────
command_exists() { command -v "$1" &> /dev/null; }
dir_exists()     { [ -d "$1" ]; }
file_exists()    { [ -f "$1" ]; }

#─────────────────────────────────────────────
# User Input
#─────────────────────────────────────────────
echo "──────────────────────────────────────────────"
echo -e "${CYAN} Nginx + SSL Setup Script ${RESET}"
echo "──────────────────────────────────────────────"
read -p "Enter domain names separated by spaces (e.g., example.com site.org): " DOMAINS

DOCUMENT_ROOT_BASE="/var/www/html"

#─────────────────────────────────────────────
# System Setup
#─────────────────────────────────────────────
info "Updating package list..."
sudo apt update -y

if command_exists nginx; then
    success "Nginx already installed."
else
    info "Installing Nginx..."
    sudo apt install -y nginx
    success "Nginx installed."
fi

if command_exists certbot; then
    success "Certbot already installed."
else
    info "Installing Certbot and Nginx plugin..."
    sudo apt install -y certbot python3-certbot-nginx
    success "Certbot installed."
fi

info "Configuring firewall..."
sudo ufw allow 'Nginx Full'

#─────────────────────────────────────────────
# Domain Setup Loop
#─────────────────────────────────────────────
for DOMAIN_NAME in $DOMAINS; do
    echo
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}Setting up ${DOMAIN_NAME}${RESET}"
    echo "──────────────────────────────────────────────"

    DOCUMENT_ROOT="$DOCUMENT_ROOT_BASE/$DOMAIN_NAME"
    CONFIG_FILE="/etc/nginx/sites-available/$DOMAIN_NAME"

    if ! dir_exists "$DOCUMENT_ROOT"; then
        info "Creating document root at $DOCUMENT_ROOT"
        sudo mkdir -p "$DOCUMENT_ROOT"
    fi

    if ! file_exists "$DOCUMENT_ROOT/index.html"; then
        info "Creating sample index.html for $DOMAIN_NAME"
        echo "<!DOCTYPE html><html><body><h1>Welcome to $DOMAIN_NAME!</h1></body></html>" | sudo tee "$DOCUMENT_ROOT/index.html" > /dev/null
    fi

    info "Generating Nginx config..."
    sudo tee "$CONFIG_FILE" > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    root $DOCUMENT_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

    sudo ln -sf "$CONFIG_FILE" /etc/nginx/sites-enabled/
done

#─────────────────────────────────────────────
# Nginx Verification
#─────────────────────────────────────────────
info "Testing Nginx configuration..."
sudo nginx -t && success "Nginx config OK."

info "Reloading Nginx..."
sudo systemctl reload nginx

#─────────────────────────────────────────────
# SSL Certificates
#─────────────────────────────────────────────
for DOMAIN_NAME in $DOMAINS; do
    info "Obtaining SSL certificate for $DOMAIN_NAME..."
    if sudo certbot --nginx -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --non-interactive --agree-tos -m admin@$DOMAIN_NAME; then
        success "SSL issued for $DOMAIN_NAME"
    else
        warn "Failed to obtain certificate for $DOMAIN_NAME"
    fi
done

#─────────────────────────────────────────────
# Certbot Renewal
#─────────────────────────────────────────────
info "Enabling automatic certificate renewal..."
sudo systemctl enable certbot.timer
sudo certbot renew --dry-run && success "Renewal dry run successful."

#─────────────────────────────────────────────
# Permissions
#─────────────────────────────────────────────
for DOMAIN_NAME in $DOMAINS; do
    DOCUMENT_ROOT="$DOCUMENT_ROOT_BASE/$DOMAIN_NAME"
    info "Setting permissions for $DOCUMENT_ROOT..."
    sudo chown -R www-data:www-data "$DOCUMENT_ROOT"
    sudo find "$DOCUMENT_ROOT" -type d -exec chmod 755 {} \;
    sudo find "$DOCUMENT_ROOT" -type f -exec chmod 644 {} \;
done

#─────────────────────────────────────────────
# Final Verification
#─────────────────────────────────────────────
info "Final Nginx test..."
sudo nginx -t && success "Configuration verified."

info "Reloading Nginx..."
sudo systemctl reload nginx
success "Nginx reloaded successfully."

#─────────────────────────────────────────────
# Summary
#─────────────────────────────────────────────
echo
echo "🎉 ${GREEN}Setup complete! Your domains are live:${RESET}"
for DOMAIN_NAME in $DOMAINS; do
    echo -e " - ${CYAN}https://$DOMAIN_NAME${RESET}"
    echo -e " - ${CYAN}https://www.$DOMAIN_NAME${RESET}"
done
echo
