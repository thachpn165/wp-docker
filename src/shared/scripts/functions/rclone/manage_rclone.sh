
# rclone_storage_list
# --------------------
# This function displays a list of configured storage remotes from the rclone configuration file.
# It extracts the storage names enclosed in square brackets from the configuration file.
#
# Globals:
#   BASE_DIR - Base directory path.
#   RCLONE_CONFIG_FILE - Name of the rclone configuration file.
#   ERROR_RCLONE_CONFIG_NOT_FOUND - Error message for missing rclone configuration file.
#
# Arguments:
#   None
#
# Outputs:
#   Prints the list of configured storage remotes to stdout.
#
# Returns:
#   0 - If the configuration file exists and storage remotes are listed successfully.
#   1 - If the configuration file does not exist or an error occurs.
#
# Dependencies:
#   is_file_exist - Function to check if a file exists.
#   print_msg - Function to print messages with different levels (e.g., error, warning, success).
#
# Example:
#   rclone_storage_list
#   Output:
#     storage1
#     storage2

# rclone_storage_delete
# ----------------------
# This function deletes a configured storage remote from the rclone configuration file.
# It allows the user to select a storage remote from a list and removes its configuration.
#
# Globals:
#   RCLONE_CONFIG_FILE - Name of the rclone configuration file.
#   ERROR_RCLONE_CONFIG_NOT_FOUND - Error message for missing rclone configuration file.
#   WARNING_RCLONE_NO_STORAGE_CONFIGURED - Warning message for no configured storage remotes.
#   LABEL_MENU_RCLONE_DELETE_STORAGE - Title message for the delete storage menu.
#   SUCCESS_RCLONE_STORAGE_REMOVED - Success message for storage removal.
#   ERROR_SELECT_OPTION_INVALID - Error message for invalid selection.
#
# Arguments:
#   None
#
# Outputs:
#   Prompts the user to select a storage remote to delete.
#   Prints success or error messages based on the operation result.
#
# Returns:
#   0 - If a storage remote is successfully deleted.
#   1 - If the configuration file does not exist, no storage remotes are configured, or an error occurs.
#
# Dependencies:
#   is_file_exist - Function to check if a file exists.
#   print_msg - Function to print messages with different levels (e.g., error, warning, success).
#
# Example:
#   rclone_storage_delete
#   Output:
#     1) storage1
#     2) storage2
#     Select a storage to delete: 1
#     Success: Storage 'storage1' has been removed.
# Function to display list of configured storages
rclone_storage_list() {
  local rclone_config="$BASE_DIR/$RCLONE_CONFIG_FILE"

  if ! is_file_exist "$rclone_config"; then
    print_msg error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  sed -n 's/^\[\(.*\)\]$/\1/p' "$rclone_config"
}

# Function to delete configured storage
rclone_storage_delete() {
  local rclone_config="$RCLONE_CONFIG_FILE"

  if ! is_file_exist "$rclone_config"; then
    print_msg error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  local storages=($(grep '^\[' "$rclone_config" | tr -d '[]'))

  if [[ ${#storages[@]} -eq 0 ]]; then
    print_msg warning "$WARNING_RCLONE_NO_STORAGE_CONFIGURED"
    return 1
  fi

  print_msg title "$LABEL_MENU_RCLONE_DELETE_STORAGE"

  select storage in "${storages[@]}"; do
    if [[ -n "$storage" ]]; then
      sed -i "/^\[$storage\]/,/^$/d" "$rclone_config"
      print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_REMOVED" "$storage")"
      break
    else
      print_msg error "$ERROR_SELECT_OPTION_INVALID"
    fi
  done
}