# =====================================
# 📄 website_management_logs – View WordPress Website Logs
# =====================================
# =====================================
# 📄 website_management_logs – View WordPress Website Logs
# =====================================

website_management_logs_logic() {
  local site_name="$1"
  local log_type="$2"
  
  if [[ -z "$site_name" ]]; then
    echo -e "${RED}${CROSSMARK} site_name is not set. Please provide a valid site name.${NC}"
    return 1
  fi

  if [[ "$log_type" == "access" ]]; then
    log_file="$SITES_DIR/$site_name/logs/access.log"
    echo -e "\n${CYAN}📜 Following Access Log: $log_file${NC}"
    
    # Tail the last 100 lines if TEST_MODE is enabled
    if [[ "$TEST_MODE" == true ]]; then
      tail -n 100 "$log_file"
    else
      tail -f "$log_file"
    fi
  elif [[ "$log_type" == "error" ]]; then
    error_log="$SITES_DIR/$site_name/logs/error.log"
    echo -e "\n${MAGENTA}📛 Following Error Log: $error_log${NC}"
    
    # Tail the last 100 lines if TEST_MODE is enabled
    if [[ "$TEST_MODE" == true ]]; then
      tail -n 100 "$error_log"
    else
      tail -f "$error_log"
    fi
  else
    echo -e "${RED}${CROSSMARK} log_type is required. Please specify access or error log.${NC}"
    return 1
  fi
}

website_management_logs() {
  echo -ne "${YELLOW}⏳ Loading log"; for i in {1..5}; do echo -n "."; sleep 0.2; done; echo "${NC}"
  
  # Call the main logic function with the correct parameters
  website_management_logs_logic "$SITE_NAME" "$LOG_TYPE"
}