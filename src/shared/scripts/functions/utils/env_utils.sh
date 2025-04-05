#!/bin/bash

# Load config if not already loaded
if [[ -z "$PROJECT_DIR" ]]; then
    echo "❌ PROJECT_DIR is not set. Please source config.sh first." >&2
    return 1
fi

# === Get value from .env ===
env_get_value() {
    local env_file="$1"
    local key="$2"
    grep -E "^${key}=" "$env_file" | cut -d '=' -f2- | tr -d '"'
}

# === Set or update a key=value in .env ===
env_set_value() {
    local key="$1"
    local value="$2"
    local env_file="$CORE_ENV"

    # Create file if it does not exist
    if [[ ! -f "$env_file" ]]; then
        touch "$env_file"
    fi

    if grep -qE "^${key}=" "$env_file"; then
        # Update existing value
        sedi "s|^${key}=.*|${key}=\"${value}\"|" "$env_file"
    else
        # Add a new line if the key does not exist
        echo "${key}=\"${value}\"" >> "$env_file"
    fi
}

# === Load environment variables from .env file ===
env_load() {
  local env_file="${CORE_ENV:-$BASE_DIR/.env}"

  if [[ -f "$env_file" ]]; then
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      key=$(echo "$key" | xargs)
      # Xoá dấu nháy nếu có, dùng hàm sedi để tương thích macOS/Linux
      temp_val="$value"
      temp_val=$(echo "$temp_val" | sed 's/^"//' | sed 's/"$//')  # hoặc dùng sedi nếu đã định nghĩa
      export "$key=$temp_val"
    done < <(grep -v '^#' "$env_file")
  else
    echo "${YELLOW}${WARNING} .env file not found at $env_file. Skipping env load.${NC}"
  fi
}