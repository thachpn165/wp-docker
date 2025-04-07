# This script provides functions to select and upload backup files using rclone.
#
# Functions:
#
# 1. select_backup_files(backup_dir)
#    - Prompts the user to select backup files from a specified directory using a dialog checklist.
#    - Parameters:
#        - backup_dir: The directory containing backup files.
#    - Returns:
#        - A list of selected files (echoed to stdout).
#    - Behavior:
#        - Checks if the directory exists.
#        - Lists files in the directory and presents them in a dialog checklist.
#        - If no files are selected, all files in the directory are returned.
#
# 2. upload_backup(storage, [file1, file2, ...])
#    - Uploads selected backup files to a specified rclone storage.
#    - Parameters:
#        - storage: The rclone storage destination (required).
#        - file1, file2, ...: Optional list of files to upload. If not provided, the user is prompted to select files.
#    - Behavior:
#        - If no files are passed, searches for a "backups" directory under $SITES_DIR and prompts the user to select files.
#        - Detects the domain name from the file path for logging purposes.
#        - Logs the upload process to a domain-specific log file.
#        - Verifies the existence of the rclone configuration file.
#        - Uploads each file to the specified rclone storage using the `rclone copy` command.
#        - Logs success or failure for each file upload.
#
# Usage:
# - Run the script directly to invoke the `upload_backup` function:
#     ./upload_backup.sh <storage> [file1 file2 ...]
# - Example:
#     ./upload_backup.sh myRemoteStorage /path/to/backup1.tar.gz /path/to/backup2.tar.gz
#
# Dependencies:
# - `dialog` for interactive file selection.
# - `rclone` for file uploads.
# - Custom utility functions:
#     - is_directory_exist: Checks if a directory exists.
#     - is_file_exist: Checks if a file exists.
#     - print_msg: Prints messages with different log levels (info, error, success, etc.).
#
# Environment Variables:
# - $SITES_DIR: Base directory containing site-specific data.
# - $RCLONE_CONFIG_FILE: Path to the rclone configuration file.
#
# Exit Codes:
# - 0: Success.
# - 1: Failure due to errors such as missing arguments, missing directories, or upload failures.
# ✅ Load configuration from any directory
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

# Load functions for website management
source "$FUNCTIONS_DIR/backup_loader.sh"

select_backup_files() {
  local backup_dir="$1"
  local choice_list=()
  local selected_files=()

  debug_log "[UPLOAD] Selecting backup files from: $backup_dir"

  if ! is_directory_exist "$backup_dir"; then
    print_and_debug error "$ERROR_NOT_EXIST: $backup_dir"
    return 1
  fi

  local backup_files=($(ls -1 "$backup_dir" 2>/dev/null))
  if [[ ${#backup_files[@]} -eq 0 ]]; then
    print_and_debug error "$ERROR_BACKUP_FILE_NOT_FOUND"
    return 1
  fi

  for file in "${backup_files[@]}"; do
    choice_list+=("$file" "$file" "off")
  done

  selected_files=$(dialog --stdout --separate-output --checklist "$PROMPT_SELECT_BACKUP_FILES" 15 60 10 "${choice_list[@]}")
  if [[ -z "$selected_files" ]]; then
    selected_files=("${backup_files[@]}")
    debug_log "[UPLOAD] No file selected, fallback to all files"
  else
    IFS=$'\n' read -r -d '' -a selected_files <<< "$(echo "$selected_files" | tr -d '\r')"
  fi

  echo "${selected_files[@]}"
}

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

    local found_dir
    found_dir=$(find "$SITES_DIR" -type d -name backups | head -n1)
    debug_log "[UPLOAD] Found backups directory: $found_dir"

    if [[ -z "$found_dir" ]]; then
      print_and_debug error "$ERROR_BACKUP_FOLDER_NOT_FOUND"
      return 1
    fi

    selected_files=($(select_backup_files "$found_dir"))
    if [[ ${#selected_files[@]} -eq 0 ]]; then
      print_and_debug error "$ERROR_BACKUP_NO_FILE_SELECTED"
      return 1
    fi

    for i in "${!selected_files[@]}"; do
      selected_files[$i]="$found_dir/${selected_files[$i]}"
    done
  else
    selected_files=("$@")
  fi

  local first_file="${selected_files[0]}"
  local domain
  domain=$(echo "$first_file" | awk -F '/' '{for(i=1;i<=NF;i++) if($i=="sites") print $(i+1)}')

  debug_log "[UPLOAD] First file: $first_file"
  debug_log "[UPLOAD] Detected domain: $domain"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_RCLONE_CANNOT_DETECT_SITE"
    return 1
  fi

  local log_file="$SITES_DIR/$domain/logs/rclone-upload.log"
  mkdir -p "$(dirname "$log_file")"

  print_msg info "$INFO_RCLONE_UPLOAD_LIST"
  for file in "${selected_files[@]}"; do
    echo "   → $file" | tee -a "$log_file"
  done

  if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
    print_and_debug error "$ERROR_RCLONE_CONFIG_NOT_FOUND"
    return 1
  fi

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