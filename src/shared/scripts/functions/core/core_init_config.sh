core_init_config() {
  # =============================================
  # 🧩 1. Tạo file .config.json nếu chưa có
  # =============================================
  json_create_if_not_exists

  # =============================================
  # 📦 2. Khởi tạo giá trị mặc định cho nhóm core
  # =============================================
  # 2.1 Thiết lập core.channel nếu chưa có
  if ! json_key_exists '.core.channel'; then
    echo -e "$PROMPT_SELECT_CHANNEL"
    PS3="$(echo -e "$PROMPT_SELECT_OPTION") "
    select opt in "official" "nightly" "dev"; do
      case "$opt" in
        official|nightly|dev)
          core_set_channel "$opt"
          print_msg success "$(printf "$SUCCESS_CORE_CHANNEL_SET" "$opt" "$JSON_CONFIG_FILE")"
          break
          ;;
        *)
          print_msg error "$ERROR_SELECT_OPTION_INVALID"
          ;;
      esac
    done
  else
    debug_log "[core_init_config] core.channel đã tồn tại: $(core_get_channel)"
  fi

  # 2.2 Khởi tạo core.installed_version nếu cần
  if ! json_key_exists '.core.installed_version'; then
    local default_version
    if core_is_dev_mode; then
      default_version="dev"
    else
      default_version="0.0.0"
    fi
    core_set_installed_version "$default_version"
    debug_log "[core_init_config] Khởi tạo core.installed_version = $default_version"
  fi

  # ==============================================
  # 🌐 3 Thiết lập ngôn ngữ mặc định
  # =============================================
  if ! json_key_exists '.core.lang'; then
    core_lang_change_prompt
  else
    debug_log "[core_init_config] Ngôn ngữ đã được đặt: $(json_get_value '.core.lang')"
  fi




  # 📌 3. (Tương lai) thêm các thiết lập mặc định khác ở đây
  # json_set_value '.core.debug_mode' false
  # json_set_value '.core.auto_update' true
  # =============================================
}