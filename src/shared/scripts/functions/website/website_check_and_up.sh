#!/bin/bash
# ==================================================
# File: website_check_and_up.sh
# Description: Functions to check and start stopped Docker containers for WordPress websites.
#              - website_check_and_up: Check all websites and start their containers if stopped.
#              - docker_check_and_start_container: Check and start a specific container for a domain.
# Functions:
#   - website_check_and_up: Check all websites and start their containers if stopped.
#       Parameters: None.
# ==================================================

website_check_and_up() {
    local domain php_container
    local started_any=false

    mapfile -t domains < <(website_list)
    if [[ ${#domains[@]} -eq 0 ]]; then
        debug_log "No website found $SITES_DIR to check and start."
        return 0
    fi

    for domain in "${domains[@]}"; do
        php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
        docker_check_and_start_container "$php_container" "$domain"
    done

    if [[ "$started_any" == true ]]; then
        echo ""
        echo "${CHECKMARK} All stopped containers have been started (or attempted to start)."
    fi
}

