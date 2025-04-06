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
        echo "🗑️ Removing file: $file_path"
        rm -f "$file_path"
    fi
}

# Remove directory if it exists
remove_directory() {
    local dir_path="$1"
    if is_directory_exist "$dir_path"; then
        echo "🗑️ Removing directory: $dir_path"
        rm -rf "$dir_path"
    fi
}

# Copy file with error checking
copy_file() {
    local src="$1"
    local dest="$2"
    if is_file_exist "$src"; then
        echo "📂 Copying file from $src -> $dest"
        cp "$src" "$dest"
    else
        echo "${CROSSMARK} Error: Source file not found: $src"
        return 1
    fi
}

# Function to check if directory exists, create if missing
is_directory_exist() {
    local dir="$1"
    local create_if_missing="$2" # If "false" then don't create

    if [ ! -d "$dir" ]; then
        if [ "$create_if_missing" != "false" ]; then
            echo "📁 [DEBUG] Creating directory: $dir"
            mkdir -p "$dir"
        else
            return 1
        fi
    fi
}

# Ask user to confirm action
confirm_action() {
  local message="$1"

  if [[ "$TEST_MODE" == true ]]; then
    echo "[TEST_MODE] Auto-confirm: $message"
    return 0
  fi

  read -rp "$message (y/n): " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Function to run command in directory using pushd/popd to ensure command runs correctly and returns to original directory
run_in_dir() {
  local target_dir="$1"
  shift
  local status

  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Directory not found: $target_dir"
    return 1
  fi

  pushd "$target_dir" > /dev/null
  debug_log "[run_in_dir] Executing: $*"
  "$@"  # gọi trực tiếp từng đối số, không eval
  status=$?
  popd > /dev/null
  return $status
}