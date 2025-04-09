# =====================================
# 📋 website_management_list – Display List of Existing Websites
# =====================================

website_management_list_logic() {
  if [[ ! -d "$SITES_DIR" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $SITES_DIR"
    return 1
  fi

  local site_list=()
  for dir in "$SITES_DIR"*/; do
    [[ -d "$dir" ]] || continue
    local domain
    domain=$(basename "$dir")

    # Kiểm tra xem domain có tồn tại trong .config.json không
    if json_key_exists ".site[\"$domain\"]"; then
      site_list+=("$domain")
    fi
  done

  print_msg label "$LABEL_WEBSITE_LIST"
  if [[ ${#site_list[@]} -eq 0 ]]; then
    print_msg error "$ERROR_NO_WEBSITES_FOUND"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done
}

website_management_list() {
  website_management_list_logic
}
