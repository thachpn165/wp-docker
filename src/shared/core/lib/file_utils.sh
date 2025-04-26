#!/bin/bash

# This script provides utility functions for file and directory operations, 
# including removing files/directories, copying files, confirming actions, 
# and running commands in specific directories.

# Functions:
# - remove_file: Remove a file if it exists.
# - remove_directory: Remove a directory if it exists.
# - copy_file: Copy a file from source to destination with validation.
# - confirm_action: Ask user to confirm a (y/n) prompt.
# - run_in_dir: Execute a command inside a directory, then return to the original.

remove_file() {
  local file_path="$1"
  if _is_file_exist "$file_path"; then
    print_msg info "$(printf "$INFO_FILE_REMOVING" "$file_path")"
    rm -f "$file_path"
  fi
}

remove_directory() {
  local dir_path="$1"
  if _is_directory_exist "$dir_path"; then
    print_msg info "$(printf "$INFO_DIR_REMOVING" "$dir_path")"
    rm -rf "$dir_path"
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"
  if _is_file_exist "$src"; then
    print_msg info "$(printf "$INFO_FILE_COPYING" "$src" "$dest")"
    cp "$src" "$dest"
  else
    print_and_debug error "$(printf "$ERROR_FILE_SOURCE_NOT_FOUND" "$src")"
    return 1
  fi
}

confirm_action() {
  local message="$1"
  local answer

  answer=$(get_input_or_test_value "$message (y/n) ")
  case "$answer" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

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
