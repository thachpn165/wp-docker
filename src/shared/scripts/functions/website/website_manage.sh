#!/usr/bin/env bash
# ==================================================
# File: website_manage.sh
# Description: Functions to manage WordPress websites, including:
#              - Restarting Docker containers for a website.
#              - Displaying website information.
#              - Listing all websites.
#              - Showing logs for a website.
# Functions:
#   - website_logic_restart: Restart a website's Docker containers.
#       Parameters:
#           $1 - domain (optional): Domain name of the website to restart.
#   - website_logic_info: Display information for a selected website.
#       Parameters:
#           $1 - domain (optional): Domain name of the website to display information for.
#   - website_logic_list: List all websites in the $SITES_DIR directory.
#       Parameters: None.
#   - website_logic_logs: Show access or error logs for a given site.
#       Parameters:
#           $1 - domain (optional): Domain name of the website.
#           $2 - log_type (optional): Type of log to display (access, error, php_error, php_slow).
# ==================================================

website_logic_restart() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    website_get_selected domain
    _is_valid_domain "$domain" || return 1
  fi

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  local site_dir="$SITES_DIR/$domain"
  local docker_compose_file="$site_dir/docker-compose.yml"
  debug_log "[website_logic_restart] site_dir=$site_dir"
  debug_log "[website_logic_restart] domain=$domain"

  print_msg step "$STEP_WEBSITE_RESTARTING: $domain"

  if ! run_cmd "docker compose -f $docker_compose_file down" true; then
    print_msg error "$ERROR_WEBSITE_STOP_FAILED: $domain"
    return 1
  fi
  if ! run_cmd "docker compose -f $docker_compose_file up -d" true; then
    print_msg error "$ERROR_WEBSITE_START_FAILED: $domain"
    return 1
  fi
  print_msg success "$SUCCESS_WEBSITE_RESTARTED: $domain"
}

website_logic_info() {
  local domain="$1"
  local db_name db_user db_pass
  local SITES_DIR="$SITES_DIR/$domain"
  local log_dir="$SITES_DIR/logs"
  local access_log="$log_dir/access.log"
  local error_log="$log_dir/error.log"
  local php_slow_log="$log_dir/php_slow.log"
  local php_error_log="$log_dir/php_error.log"

  if [[ -z "$domain" ]]; then
    website_get_selected domain
    _is_valid_domain "$domain" || return 1
  fi

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  db_name=$(json_get_site_value "$domain" "db_name")
  db_user=$(json_get_site_value "$domain" "db_user")
  db_pass=$(json_get_site_value "$domain" "db_pass")
  php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
  cache_type=$(json_get_site_value "$domain" "cache")

  print_msg label "ℹ️ $LABEL_WEBSITE_INFO: ${YELLOW}$domain${NC}"
  print_msg sub-label "   $LABEL_WEBSITE_DOMAIN: ${YELLOW}$domain${NC}"
  print_msg sub-label "   $LABEL_WEBSITE_DB_NAME: ${YELLOW}$db_name${NC}"
  print_msg sub-label "   $LABEL_WEBSITE_DB_USER: ${YELLOW}$db_user${NC}"
  print_msg sub-label "   $LABEL_WEBSITE_DB_PASS: ${YELLOW}$db_pass${NC}"
  print_msg sub-label "   PHP Container: ${YELLOW}$php_container${NC}"
  print_msg sub-label "   Cache: ${YELLOW}$cache_type${NC}"

  local backup_enabled backup_interval backup_storage next_run last_file now_ts last_run_ts interval_days interval_sec
  backup_enabled=$(json_get_site_value "$domain" "backup_schedule.enabled")
  if [[ "$backup_enabled" == "true" ]]; then
    interval_days=$(json_get_site_value "$domain" "backup_schedule.interval_days")
    backup_storage=$(json_get_site_value "$domain" "backup_schedule.storage")
    print_msg sub-label "   Backup: ${YELLOW}Enabled every $interval_days day(s) → $backup_storage${NC}"

    last_file="$BASE_DIR/.cron/.backup_${domain}"
    if [[ -f "$last_file" ]]; then
      now_ts=$(date +%s)
      last_run_ts=$(<"$last_file")
      interval_sec=$((interval_days * 86400))
      next_run=$((last_run_ts + interval_sec))
      next_run_formatted=$(date -d "@$next_run" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "$next_run" '+%Y-%m-%d %H:%M:%S')
      print_msg sub-label "   Next Backup: ${YELLOW}$next_run_formatted${NC}"
    fi
  else
    print_msg sub-label "   Backup: ${YELLOW}Disabled${NC}"
  fi

  print_msg label "📝 Log: ${YELLOW}$log_dir${NC}"
  print_msg sub-label "   Access Log: ${YELLOW}$access_log${NC}"
  print_msg sub-label "   Error Log: ${YELLOW}$error_log${NC}"
  print_msg sub-label "   PHP Slow Log: ${YELLOW}$php_slow_log${NC}"
  print_msg sub-label "   PHP Error Log: ${YELLOW}$php_error_log${NC}"
  echo ""

  print_msg sub-label "$LABEL_SITE_DIR: ${YELLOW}$SITES_DIR${NC}"
}

website_logic_list() {
  if [[ ! -d "$SITES_DIR" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $SITES_DIR"
    return 1
  fi

  mapfile -t site_list < <(ls -1 "$SITES_DIR")

  print_msg label "$LABEL_WEBSITE_LIST"
  if [ ${#site_list[@]} -eq 0 ]; then
    print_msg error "$ERROR_NO_WEBSITES_FOUND"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done
}

website_logic_logs() {
  local domain="$1"
  local log_type="$2"

  if [[ -z "$domain" ]]; then
    website_get_selected domain
    _is_valid_domain "$domain" || return 1
  fi

  local access_log="$SITES_DIR/$domain/logs/access.log"
  local error_log="$SITES_DIR/$domain/logs/error.log"
  local php_slow_log="$SITES_DIR/$domain/logs/php_slow.log"
  local php_error_log="$SITES_DIR/$domain/logs/php_error.log"

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  if [[ -z "$log_type" ]]; then
    echo -e "${YELLOW}⚡ You are about to view logs for the website '$domain'. Choose log type:${NC}"
    echo "1. Access Logs"
    echo "2. Error Logs"
    echo "3. PHP Error Logs"
    echo "4. PHP Slow Logs"
    log_option=$(select_from_list "$PROMPT_SELECT_OPTION (1-4)" "1" "2" "3" "4")
    case "$log_option" in
      1) log_type="access" ;;
      2) log_type="error" ;;
      3) log_type="php_error" ;;
      4) log_type="php_slow" ;;
      *) print_msg error "$ERROR_INVALID_LOG_TYPE: $log_option"; return 1 ;;
    esac
  fi

  if [[ ! -d "$SITES_DIR/$domain/logs" ]]; then
    print_msg error "$ERROR_LOGS_DIR_NOT_FOUND: $SITES_DIR/logs"
    return 1
  fi

  case "$log_type" in
    access) tail -f "$access_log" ;;
    error) tail -f "$error_log" ;;
    php_error) tail -f "$php_error_log" ;;
    php_slow) tail -f "$php_slow_log" ;;
    *) print_msg error "$ERROR_INVALID_LOG_TYPE: $log_type"; return 1 ;;
  esac
}