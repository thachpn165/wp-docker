wordpress_auto_update_plugin_logic() {

    domain="$1"  # site_name will be passed from the menu file or CLI

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER="$domain-php"
    
    # **Handle enabling/disabling automatic plugin updates**
    if [[ "$2" == "enable" ]]; then
        echo -e "${YELLOW}🔄 Enabling automatic updates for all plugins...${NC}"
        bash $CLI_DIR/wordpress_wp_cli.sh --domain="${domain}" -- plugin auto-updates enable --all
        exit_if_error "$?" "Unable to enable automatic updates for plugins on '$domain'."
        echo -e "${GREEN}${CHECKMARK} Automatic updates have been enabled for all plugins on '$domain'.${NC}"
    elif [[ "$2" == "disable" ]]; then
        echo -e "${YELLOW}🔄 Disabling automatic updates for all plugins...${NC}"
        bash $CLI_DIR/wordpress_wp_cli.sh --domain="${domain}" -- plugin auto-updates disable --all
        exit_if_error "$?" "Unable to disable automatic updates for plugins on '$domain'."
        echo -e "${GREEN}${CHECKMARK} Automatic updates have been disabled for all plugins on '$domain'.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Invalid option.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW} Current plugin status on '$domain':${NC}"
    bash $CLI_DIR/wordpress_wp_cli.sh --domain="${domain}" -- plugin list --fields=name,status,auto_update --format=table

}