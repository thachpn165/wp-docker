#!/bin/bash
# ==================================================
# File: manage_rclone.sh
# Description: Functions to manage Rclone storages, including listing configured storages 
#              and deleting selected storages from the configuration file.
# Functions:
#   - rclone_storage_list: List all configured Rclone storages from the config file.
#       Parameters: None.
#   - rclone_storage_delete: Prompt the user to select and delete an Rclone storage.
#       Parameters: None.
# ==================================================

rclone_storage_list() {
  local rclone_config="$RCLONE_CONFIG_FILE"

  debug_log "[RCLONE] Config path: $rclone_config"

  if ! _is_file_exist "$rclone_config"; then
    print_and_debug error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  # Read each storage and print in the format: 📦 storage_name (type)
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

      # Delete from the line containing [$storage] to the next blank line
      # Compatible with both macOS and Linux sed
      sedi "/^\[$storage\]/,/^\s*$/d" "$rclone_config"

      print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_REMOVED" "$storage")"
      break
    else
      print_and_debug error "$ERROR_SELECT_OPTION_INVALID"
    fi
  done
}