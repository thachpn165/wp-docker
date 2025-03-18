#!/bin/bash

generate_wp_admin() {
    ADMIN_USER="admin_$(openssl rand -hex 6)"
    ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
}
