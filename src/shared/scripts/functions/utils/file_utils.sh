#!/bin/bash

# Check if a file exists
is_file_exist() {
  local file_path="$1"
  [[ -f "$file_path" ]]
}

# Remove file if it exists
remove_file() {
  local file_path="$1"
  if is_file_exist "$file_path"; then
    print_msg info "$(printf "$INFO_FILE_REMOVING" "$file_path")"
    rm -f "$file_path"
  fi
}

# Remove directory if it exists
remove_directory() {
  local dir_path="$1"
  if is_directory_exist "$dir_path"; then
    print_msg info "$(printf "$INFO_DIR_REMOVING" "$dir_path")"
    rm -rf "$dir_path"
  fi
}

# Copy file with error checking
copy_file() {
  local src="$1"
  local dest="$2"
  if is_file_exist "$src"; then
    print_msg info "$(printf "$INFO_FILE_COPYING" "$src" "$dest")"
    cp "$src" "$dest"
  else
    print_and_debug error "$(printf "$ERROR_FILE_SOURCE_NOT_FOUND" "$src")"
    return 1
  fi
}

# Check if directory exists, create if missing
is_directory_exist() {
  local dir="$1"
  local create_if_missing="$2" # If "false" then don't create

  if [[ ! -d "$dir" ]]; then
    if [[ "$create_if_missing" != "false" ]]; then
      print_msg debug "$(printf "$INFO_DIR_CREATING" "$dir")"
      mkdir -p "$dir"
    else
      return 1
    fi
  fi
}

# Ask user to confirm action
confirm_action() {
  local message="$1"
  local answer

  answer=$(get_input_or_test_value "$message (y/n)")
  case "$answer" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Run command in directory and return to original path
run_in_dir() {
  local target_dir="$1"
  shift

  if [[ ! -d "$target_dir" ]]; then
    print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$target_dir")"
    return 1
  fi

  debug_log "[run_in_dir] Executing in: $target_dir → $*"

  (
    cd "$target_dir" || exit 1
    "$@"
  )
  ensure_safe_cwd
  return $?
}