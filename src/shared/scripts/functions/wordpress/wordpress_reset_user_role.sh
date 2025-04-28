#!/bin/bash
# ==================================================
# File: wordpress_reset_user_role.sh
# Description: Functions to reset WordPress user roles to their default state, including:
#              - Prompting the user to select a website for resetting roles.
#              - Executing WP-CLI commands to reset all roles for a given site.
# Functions:
#   - wordpress_prompt_reset_roles: Prompt user to select a website and reset roles.
#       Parameters: None.
#   - reset_user_role_logic: Reset all WordPress user roles to default for a given site.
#       Parameters:
#           $1 - domain: Domain name of the website.
# ==================================================

wordpress_prompt_reset_roles() {
    # Prompt user to select a website and reset roles.
    # Parameters: None.

    local domain
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi

    # Call CLI to reset roles
    wordpress_cli_reset_roles --domain="$domain"
}

reset_user_role_logic() {
    # Reset all WordPress user roles to default for a given site.
    # Parameters:
    #   $1 - domain: Domain name of the website.

    local domain="$1"
    _is_valid_domain "$domain" || return 1
    print_msg step "$STEP_WORDPRESS_RESET_ROLE"
    wordpress_wp_cli_logic "$domain" "role reset --all"
    exit_if_error "$?" "$ERROR_WORDPRESS_RESET_ROLE"
    print_msg success "$(printf "$SUCCESS_WORDPRESS_RESET_ROLE" "$domain")"
}
