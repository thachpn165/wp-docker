#!/bin/bash

# =====================================
# is_file_exist: Check if a file exists
# Parameters:
#   $1 - file_path
# Returns:
#   0 if exists, 1 if not
# =====================================
is_file_exist() {
  local file_path="$1"
  [[ -f "$file_path" ]]
}

# =====================================
# remove_file: Remove a file if it exists
# Parameters:
#   $1 - file_path
# =====================================
remove_file() {
  local file_path="$1"
  if is_file_exist "$file_path"; then
    print_msg info "$(printf "$INFO_FILE_REMOVING" "$file_path")"
    rm -f "$file_path"
  fi
}

# =====================================
# remove_directory: Remove a directory if it exists
# Parameters:
#   $1 - dir_path
# Requires:
#   is_directory_exist must be defined
# =====================================
remove_directory() {
  local dir_path="$1"
  if is_directory_exist "$dir_path"; then
    print_msg info "$(printf "$INFO_DIR_REMOVING" "$dir_path")"
    rm -rf "$dir_path"
  fi
}

# =====================================
# copy_file: Copy file from source to destination with validation
# Parameters:
#   $1 - src
#   $2 - dest
# Fails if source file does not exist
# =====================================
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

# =====================================
# is_directory_exist: Check if a directory exists
# Parameters:
#   $1 - dir: Directory path
#   $2 - create_if_missing (optional): If not "false", directory will be created
# Returns:
#   0 if directory exists or is created, 1 otherwise
# =====================================
is_directory_exist() {
  local dir="$1"
  local create_if_missing="$2"

  if [[ ! -d "$dir" ]]; then
    if [[ "$create_if_missing" == "true" ]]; then
      debug_log "[is_directory_exist] Directory not exist, creating: $dir"
      print_msg debug "$MSG_NOT_FOUND : $dir"
      mkdir -p "$dir"
    else
      return 1
    fi
  fi
}

# =====================================
# confirm_action: Ask user to confirm a (y/n) prompt
# Parameters:
#   $1 - message to show
# Returns:
#   0 if user confirms, 1 otherwise
# =====================================
confirm_action() {
  local message="$1"
  local answer

  answer=$(get_input_or_test_value "$message (y/n)")
  case "$answer" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# =====================================
# run_in_dir: Execute a command inside a directory, then return to original
# Parameters:
#   $1 - target_dir
#   $@ - command to execute
# Returns:
#   Exit code of executed command
# =====================================
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