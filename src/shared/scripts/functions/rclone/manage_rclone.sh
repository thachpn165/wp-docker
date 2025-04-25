# =====================================
# rclone_storage_list: List all configured Rclone storages from config file
# Requires:
#   - $RCLONE_CONFIG_FILE to be defined and exist
# Outputs:
#   - Echoes storage names (sections in rclone.conf)
# =====================================
rclone_storage_list() {
  local rclone_config="$RCLONE_CONFIG_FILE"

  debug_log "[RCLONE] Config path: $rclone_config"

  if ! _is_file_exist "$rclone_config"; then
    print_and_debug error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  # Đọc từng storage và in theo định dạng: 📦 thachdrive (drive)
  awk '
    /^\[/ {
      gsub(/[\[\]]/, "", $0)
      current = $0
    }
    /^type[ \t]*=/ {
      gsub(/^[ \t]*type[ \t]*=[ \t]*/, "", $0)
      type = $0
      printf("📦 %s (%s)\n", current, type)
    }
  ' "$rclone_config"
}

# =====================================
# rclone_storage_delete: Prompt user to select and delete an Rclone storage
# Requires:
#   - $RCLONE_CONFIG_FILE must exist
#   - sed to delete storage block from config file
# =====================================
rclone_storage_delete() {
  local rclone_config="$RCLONE_CONFIG_FILE"

  debug_log "[RCLONE] Loading config: $rclone_config"

  # Check if rclone config file exists
  if ! _is_file_exist "$rclone_config"; then
    print_and_debug error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  # Parse list of storages from config
  local storages=()
  mapfile -t storages < <(grep '^\[' "$rclone_config" | tr -d '[]')
  debug_log "[RCLONE] Found storages: ${storages[*]}"

  if [[ ${#storages[@]} -eq 0 ]]; then
    print_and_debug warning "$WARNING_RCLONE_NO_STORAGE_CONFIGURED"
    return 1
  fi

  print_msg title "$LABEL_MENU_RCLONE_DELETE_STORAGE"

  select storage in "${storages[@]}"; do
    if [[ -n "$storage" ]]; then
      debug_log "[RCLONE] Deleting storage: $storage"

      # Xóa từ dòng chứa [$storage] đến dòng trắng kế tiếp
      # Đây là đoạn dùng sed tương thích macOS + Linux
      sedi "/^\[$storage\]/,/^\s*$/d" "$rclone_config"

      print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_REMOVED" "$storage")"
      break
    else
      print_and_debug error "$ERROR_SELECT_OPTION_INVALID"
    fi
  done
}