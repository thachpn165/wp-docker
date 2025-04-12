#!/bin/bash
#shellcheck disable=SC2207
website_prompt_update_template() {

  # Lấy danh sách các website cần cập nhật template
  outdated_sites=($(website_logic_update_template))

  # Kiểm tra xem có website nào cần cập nhật không
  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    echo -e "${YELLOW}${WARNING} No outdated sites found.${NC}"
    return 0  # Không tiếp tục nếu không có website cần cập nhật
  fi

  # Hiển thị danh sách các website cần cập nhật template
  echo -e "${CYAN}🔧 List of sites needing update:${NC}"
  for site in "${outdated_sites[@]}"; do
    echo "  $site"
  done

  # Hỏi người dùng có muốn cập nhật website nào không
  SELECTED_SITE=$(select_from_list "🔹 Select a website to update:" "${outdated_sites[@]}")
  if [[ -z "$SELECTED_SITE" ]]; then
    echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
    return 1  # Nếu người dùng không chọn website hợp lệ, dừng lại
  fi

  # Tiến hành cập nhật website đã chọn
  echo -e "${GREEN}${CHECKMARK} Updating website '$SELECTED_SITE'...${NC}"
  bash "$SCRIPTS_DIR/cli/website_update_template.sh" --domain="$SELECTED_SITE"

}

website_logic_update_template() {
  TEMPLATE_VERSION_NEW=$(cat "$BASE_DIR/shared/templates/.template_version" 2>/dev/null || echo "unknown")

  outdated_sites=()
  if [[ -z "$domain" ]]; then
    website_prompt_update_template
  fi

  for site_path in "$SITES_DIR/"*/; do
    [ -d "$site_path" ] || continue
    domain=$(basename "$site_path")
    site_ver_file="$site_path/.template_version"
    site_template_version=$(cat "$site_ver_file" 2>/dev/null || echo "unknown")

    if [[ "$site_template_version" != "$TEMPLATE_VERSION_NEW" ]]; then
      outdated_sites+=("$domain")
    fi
  done

  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    return 1 # No outdated sites found
  fi

  echo "${outdated_sites[@]}" # Return list of outdated sites to caller
}
