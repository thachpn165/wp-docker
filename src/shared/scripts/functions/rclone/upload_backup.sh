# shellcheck disable=SC1091
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load backup-related functions
safe_source "$FUNCTIONS_DIR/backup_loader.sh"

# =====================================
# select_backup_files: Show a dialog to let user select backup files
# Parameters:
#   $1 - backup_dir: Directory to scan for backup files
# Returns:
#   List of selected backup files via stdout
# =====================================
select_backup_files() {
  local backup_dir="$1"
  local choice_list=()
  local selected_files=()

  debug_log "[UPLOAD] Selecting backup files from: $backup_dir"

  # Check if backup directory exists
  if ! is_directory_exist "$backup_dir"; then
    print_and_debug error "$ERROR_NOT_EXIST: $backup_dir"
    return 1
  fi

  # Read list of backup files
  mapfile -t backup_files < <(ls -1 "$backup_dir" 2>/dev/null)
  if [[ ${#backup_files[@]} -eq 0 ]]; then
    print_and_debug error "$ERROR_BACKUP_FILE_NOT_FOUND"
    return 1
  fi

  # Prepare dialog checklist
  for file in "${backup_files[@]}"; do
    choice_list+=("$file" "$file" "off")
  done

  # Show dialog for selection
  local selected_raw
  selected_raw=$(dialog --stdout --separate-output --checklist "$PROMPT_SELECT_BACKUP_FILES" 15 60 10 "${choice_list[@]}")

  if [[ $? -ne 0 ]]; then
    print_and_debug warning "$WARNING_BACKUP_DIALOG_CANCELED"
    return 1
  fi

  # If nothing selected, fallback to all files
  if [[ -z "$selected_raw" ]]; then
    selected_files=("${backup_files[@]}")
    debug_log "[UPLOAD] No file selected, fallback to all files"
  else
    # Convert multi-line dialog output to array
    IFS=$'\n' read -r -d '' -a selected_files <<< "$(echo "$selected_raw" | tr -d '\r')"$'\0'
  fi

  # Return result via stdout
  printf "%s\n" "${selected_files[@]}"
}

# =====================================
# upload_backup: Upload backup files to Rclone storage
# Usage:
#   upload_backup <storage> [file1 file2 ...]
# If no files are passed, user will be prompted to select
# =====================================
upload_backup() {
  print_msg info "$INFO_RCLONE_UPLOAD_START"

  if [[ $# -lt 1 ]]; then
    print_and_debug error "$ERROR_RCLONE_STORAGE_REQUIRED"
    echo "Usage: upload_backup <storage> [file1 file2 ...]"
    return 1
  fi

  local storage="$1"
  shift

  local selected_files=()
  if [[ $# -eq 0 ]]; then
    print_msg info "$INFO_BACKUP_NO_FILES_PASSED"

    # Try to find a backup directory
    local found_dir
    found_dir=$(find "$SITES_DIR" -type d -name backups | head -n1)
    debug_log "[UPLOAD] Found backups directory: $found_dir"

    if [[ -z "$found_dir" ]]; then
      print_and_debug error "$ERROR_BACKUP_FOLDER_NOT_FOUND"
      return 1
    fi

    # Prompt user to select files
    mapfile -t selected_files < <(select_backup_files "$found_dir")
    if [[ ${#selected_files[@]} -eq 0 ]]; then
      print_and_debug error "$ERROR_BACKUP_NO_FILE_SELECTED"
      return 1
    fi

    # Convert to absolute paths
    for i in "${!selected_files[@]}"; do
      selected_files[$i]="$found_dir/${selected_files[$i]}"
    done
  else
    selected_files=("$@")
  fi

  # Detect domain from file path
  local first_file="${selected_files[0]}"
  local domain
  domain=$(echo "$first_file" | awk -F '/' '{for(i=1;i<=NF;i++) if($i=="sites") print $(i+1)}')

  debug_log "[UPLOAD] First file: $first_file"
  debug_log "[UPLOAD] Detected domain: $domain"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_RCLONE_CANNOT_DETECT_SITE"
    return 1
  fi

  # Prepare log file path
  local log_file="$SITES_DIR/$domain/logs/rclone-upload.log"
  mkdir -p "$(dirname "$log_file")"

  # Print selected files to upload
  print_msg info "$INFO_RCLONE_UPLOAD_LIST"
  for file in "${selected_files[@]}"; do
    echo "   → $file" | tee -a "$log_file"
  done

  # Validate rclone config exists
  if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
    print_and_debug error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

  # Start uploading each file
  for file in "${selected_files[@]}"; do
    print_msg run "$(printf "$INFO_RCLONE_UPLOADING" "$file")" | tee -a "$log_file"
    rclone --config "$RCLONE_CONFIG_FILE" copy "$file" "$storage:backup-folder" --progress --log-file "$log_file"

    if [[ $? -eq 0 ]]; then
      print_msg success "$(printf "$SUCCESS_RCLONE_UPLOAD_SINGLE" "$file")" | tee -a "$log_file"
    else
      print_and_debug error "$(printf "$ERROR_RCLONE_UPLOAD_FAILED_SINGLE" "$file")" | tee -a "$log_file"
    fi
  done

  print_msg success "$SUCCESS_RCLONE_UPLOAD_DONE" | tee -a "$log_file"
}

# Execute function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  upload_backup "$@"
fi