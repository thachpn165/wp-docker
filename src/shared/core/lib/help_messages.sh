# shared/help/help_messages.sh

help_cli_global() {
    echo -e "${GREEN}Usage${NC}: wpdocker [subcommand]"
    echo ""
    echo "  website       - Manage websites"
    echo "  ssl           - SSL installation and checking"
    echo "  php           - Change PHP version, edit ini/conf"
    echo "  database      - Import, export, reset database"
    echo "  wordpress     - Tools for WordPress (cache, security, CLI)"
    echo "  backup        - Website and DB backup tools"
    echo "  core          - Update WP Docker system"
    echo "  cron          - Scheduled jobs (renew SSL, backup)"
    echo "  system        - Docker system tools"
    echo ""
    echo "${YELLOW}Tip:${NC} Run 'wpdocker <subcommand> --help' for details"
}

help_cli_core() {
    echo -e "${GREEN}Usage${NC}: wpdocker core [subcommand]"
    echo "  version           - Show current and latest core version"
    echo "  update            - Update to latest version"
    echo "  uninstall         - Remove WP Docker"
    echo "  channel change    - Switch update channel"
    echo "  channel check     - Show current channel"
    echo "  lang change       - Change CLI language"
    echo "  lang list         - List supported languages"
    echo ""
}

help_cli_php() {
    echo -e "${GREEN}Usage${NC}: wpdocker php [subcommand]"
    echo "  change         - Switch PHP version"
    echo "  get            - View current PHP version"
    echo "  rebuild        - Rebuild PHP container"
    echo "  edit conf      - Edit php-fpm.conf"
    echo "  edit ini       - Edit php.ini"
    echo ""
}
