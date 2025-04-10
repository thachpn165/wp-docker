#!/usr/bin/env bash
# shellcheck disable=SC1091
# =====================================
# 🔄 Website restart functions
# =====================================

website_logic_restart() {
  local domain="$1"
  local SITES_DIR="$SITES_DIR/$domain"
  # Nếu domain trống, gọi select_website để chọn domain
  if [[ -z "$domain" ]]; then
    select_website
    local SITES_DIR="$SITES_DIR/$domain"
  fi

  # Kiểm tra nếu domain vẫn trống sau khi chọn
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  debug_log "[website_logic_restart] domain=$domain"

  # Restart the website using Docker Compose
  print_msg step "$STEP_WEBSITE_RESTARTING: $domain"
  cd "$SITES_DIR" || return
  docker-compose down && docker-compose up -d
  cd "$BASH_DIR" || return

  print_msg success "$SUCCESS_WEBSITE_RESTARTED: $domain"
}

# =====================================
# Website info function
# =====================================
website_logic_info() {
  local domain="$1"
  local db_name db_user db_pass
  local SITES_DIR="$SITES_DIR/$domain"
  # If domain is not provided, call select_website to choose one
  if [[ -z "$domain" ]]; then
    select_website
  fi

  # Check if domain is still empty after selection
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  # Fetch website information from .config.json
  db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
  db_user=$(json_get_site_value "$domain" "MYSQL_USER")
  db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")

  # Display website information
  print_msg label "$LABEL_WEBSITE_INFO: ${YELLOW}$domain${NC}"
  print_msg sub-label "$LABEL_WEBSITE_DOMAIN: ${YELLOW}$domain${NC}"
  print_msg sub-label "$LABEL_WEBSITE_DB_NAME: ${YELLOW}$db_name${NC}"
  print_msg sub-label "$LABEL_WEBSITE_DB_USER: ${YELLOW}$db_user${NC}"
  print_msg sub-label "$LABEL_WEBSITE_DB_PASS: ${YELLOW}$db_pass${NC}"
  print_msg sub-label "$LABEL_SITE_DIR: ${YELLOW}$SITES_DIR${NC}"
}

# =====================================
# Website listing function
# =====================================
website_logic_list() {
  if [[ ! -d "$SITES_DIR" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $SITES_DIR"
    return 1
  fi

  mapfile -t site_list < <(ls -1 "$SITES_DIR")

  #echo -e "${YELLOW}📋 List of Existing Websites:${NC}"
  print_msg label "$LABEL_WEBSITE_LIST"
  if [ ${#site_list[@]} -eq 0 ]; then
    #echo -e "${RED}${CROSSMARK} No websites are installed.${NC}"
    print_msg error "$ERROR_NO_WEBSITES_FOUND"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done
}

# =====================================
# Website logs function
# =====================================
website_logic_logs() {
  local domain="$1"
  local log_type="$2"
  local access_log="$SITES_DIR/$domain/logs/access.log"
  local error_log="$SITES_DIR/$domain/logs/error.log"

  # If domain is not provided, call select_website to choose one
  if [[ -z "$domain" ]]; then
    select_website
    local access_log="$SITES_DIR/$domain/logs/access.log"
    local error_log="$SITES_DIR/$domain/logs/error.log"
  fi

  # Check if domain is still empty after selection
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  # Check if log_type is provided
  if [[ -z "$log_type" ]]; then
    echo -e "${YELLOW}⚡ You are about to view logs for the website '$domain'. Choose log type:${NC}"
    echo "1. Access Logs"
    echo "2. Error Logs"
    # Read user input
    log_option=$(select_from_list "$PROMPT_SELECT_OPTION (1-2)" "1" "2")
    if [[ "$log_option" == "1" ]]; then
      log_type="access"
    elif [[ "$log_option" == "2" ]]; then
      log_type="error"
    else
      print_msg error "$ERROR_INVALID_LOG_TYPE: $log_option"
      return 1
    fi
  fi

  # Check if the logs directory exists
  if [[ ! -d "$SITES_DIR/$domain/logs" ]]; then
    print_msg error "$ERROR_LOGS_DIR_NOT_FOUND: $SITES_DIR/logs"
    return 1
  fi

  debug_log "Selected domain: $domain"
  debug_log "Selected log type: $log_type"
  debug_log "error_log: $error_log"
  debug_log "access_log: $access_log"

  echo ""${NC}
  # Display logs based on the log type
  case "$log_type" in
  access)
    echo -e "\n${CYAN}📜 Following Access Log (Ctrl+C to Exit): $access_log${NC}"
    tail -f "$access_log"
    ;;
  error)
    echo -e "\n${MAGENTA}📛 Following Error Log (Ctrl+C to Exit): $error_log${NC}"
    tail -f "$error_log"
    ;;
  *)
    print_msg error "$ERROR_INVALID_LOG_TYPE: $log_type"
    return 1
    ;;
  esac
}
