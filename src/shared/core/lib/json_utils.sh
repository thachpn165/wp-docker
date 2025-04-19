#!/bin/bash

# =============================================
# JSON Utility Functions - Used across project
# =============================================

# =====================================
# JSON_CONFIG_FILE: Default JSON config file path
# =====================================
JSON_CONFIG_FILE="$BASE_DIR/.config.json"

# =====================================
# json_create_if_not_exists: Create empty JSON file if it doesn't exist
# Parameters:
#   $1 - file (optional, defaults to $JSON_CONFIG_FILE)
# =====================================
json_create_if_not_exists() {
  local file="${1:-$JSON_CONFIG_FILE}"
  if [[ ! -f "$file" ]]; then
    echo "{}" > "$file"
    debug_log "Created new JSON config file: $file"
  fi
}

# =====================================
# json_get_value: Get a value from JSON file by jq path
# Usage:
#   json_get_value ".site[\"example.com\"].MYSQL_USER"
# Parameters:
#   $1 - jq key path
#   $2 - file (optional)
# Output:
#   Echoes the value or empty if not found
# =====================================
json_get_value() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  local value
  value=$(jq -r "$key" "$file" 2>/dev/null)
  debug_log "json_get_value: file=$file key=$key value=$value"
  echo "$value"
}
# =============================================
# 🔓 json_get_value_decrypted – Decrypt global value from .config.json
# ---------------------------------------------
# Parameters:
#   $1 - jq path (e.g. .mysql.root_password)
#   $2 - file (optional)
# =============================================
json_get_value_decrypted() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  local keyfile="$BASE_DIR/.secret_key"

  if [[ -z "$key" ]]; then
    print_and_debug error "❌ Missing key in json_get_value_decrypted"
    return 1
  fi

  local encrypted
  encrypted=$(json_get_value "$key" "$file")

  if [[ "$encrypted" =~ ^ENC:: ]]; then
    local enc_data="${encrypted#ENC::}"

    if [[ ! -f "$keyfile" ]]; then
      print_msg warning "🔐 Secret key file not found. Regenerating: $keyfile"
      openssl rand -hex 32 > "$keyfile"
    fi

    echo "$enc_data" | openssl enc -aes-256-cbc -a -d -salt -pass file:"$keyfile" 2>/dev/null
  else
    echo "$encrypted"
  fi
}

# =============================================
# 🔐 json_set_value_encrypted – Set encrypted global value into .config.json
# ---------------------------------------------
# Parameters:
#   $1 - jq path (e.g. .mysql.root_password)
#   $2 - plain-text value
#   $3 - file (optional)
# =============================================
json_set_value_encrypted() {
  local key="$1"
  local value="$2"
  local file="${3:-$JSON_CONFIG_FILE}"
  local keyfile="$BASE_DIR/.secret_key"

  if [[ -z "$key" || -z "$value" ]]; then
    print_and_debug error "❌ Missing param: key or value in json_set_value_encrypted"
    return 1
  fi

  # Tạo file key nếu chưa có
  if [[ ! -f "$keyfile" ]]; then
    print_msg warning "🔐 No secret key found. Generating new key at $keyfile"
    openssl rand -hex 32 > "$keyfile"
  fi

  local encrypted
  encrypted="ENC::$(echo -n "$value" | openssl enc -aes-256-cbc -a -salt -pass file:"$keyfile" 2>/dev/null)"

  json_set_string_value "$key" "$encrypted" "$file"
}
# =====================================
# json_set_value: Set a value in JSON file by jq path
# Usage:
#   json_set_value ".site[\"example.com\"].MYSQL_USER" "wpuser"
# Parameters:
#   $1 - jq path
#   $2 - value to set
#   $3 - file (optional)
# =====================================
json_set_value() {
  local key="$1"
  local value="$2"
  local file="${3:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"

  local tmp_file
  tmp_file=$(mktemp)

  if jq "$key = \"$value\"" "$file" > "$tmp_file"; then
    mv -f "$tmp_file" "$file"
    debug_log "json_set_value: file=$file key=$key value=$value"
  else
    debug_log "json_set_value ERROR: Failed to set $key in $file"
    rm -f "$tmp_file"
  fi
}

json_set_string_value() {
  local key="$1"
  local value="$2"
  local file="${3:-$JSON_CONFIG_FILE}"

  json_create_if_not_exists "$file"
  debug_log "[json_set_string_value] START → key=$key value=$value file=$file"

  local tmp_file
  tmp_file=$(mktemp)

  if jq --arg val "$value" "$key = \$val" "$file" > "$tmp_file"; then
    mv -f "$tmp_file" "$file"
    debug_log "[json_set_string_value] SUCCESS → key=$key"
  else
    debug_log "[json_set_string_value] ERROR → failed to set $key in $file"
    rm -f "$tmp_file"
  fi
}
# =====================================
# json_delete_key: Delete a key from JSON file
# Usage:
#   json_delete_key ".site[\"example.com\"]"
# Automatically removes empty domain objects
# =====================================
json_delete_key() {
  local key="$1"
  local domain
  domain=$(echo "$key" | sed -E 's/.*\[\"(.*)\"\].*/\1/')

  local tmp_file
  tmp_file=$(mktemp)
  jq "del($key)" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"

  # If .site["domain"] is now an empty object {}, remove it
  if jq -e ".site[\"$domain\"] | type == \"object\" and (keys | length == 0)" "$JSON_CONFIG_FILE" > /dev/null; then
    jq "del(.site[\"$domain\"])" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"
    debug_log "[json_delete_key] Removed empty domain entry: $domain"
  fi
}

# =====================================
# json_key_exists: Check if a key exists in JSON file
# Usage:
#   json_key_exists ".site[\"example.com\"].MYSQL_USER"
# Parameters:
#   $1 - jq path
#   $2 - file (optional)
# Returns:
#   0 if key exists, 1 otherwise
# =====================================
json_key_exists() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"

  json_create_if_not_exists "$file"
  debug_log "[json_key_exists] Checking key: $key in file: $file"

  if jq -e "$key != null" "$file" >/dev/null 2>&1; then
    debug_log "[json_key_exists] Key exists: $key"
    return 0
  else
    debug_log "[json_key_exists] Key does not exist: $key"
    return 1
  fi
}

# =============================================
# JSON Site Utilities – Manage .site["$domain"]
# =============================================

# =====================================
# json_get_site_value: Get a value from .site["domain"]
# Parameters:
#   $1 - domain
#   $2 - key
#   $3 - file (optional)
# Output:
#   Value or empty string
# =====================================
json_get_site_value() {
  local domain="$1"
  local key="$2"
  local file="${3:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain or --key"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_get_value "$path" "$file"
}

# =====================================
# json_set_site_value: Set a value inside .site["domain"]
# Parameters:
#   $1 - domain
#   $2 - key
#   $3 - value
#   $4 - file (optional)
# =====================================
json_set_site_value() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local file="${4:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" || -z "$value" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain, --key or --value"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_set_value "$path" "$value" "$file"
}

# =====================================
# json_delete_site_field: Delete a specific key in .site["domain"]
# Parameters:
#   $1 - domain
#   $2 - key
#   $3 - file (optional)
# =====================================
json_delete_site_field() {
  local domain="$1"
  local key="$2"
  local file="${3:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain or --key"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_delete_key "$path"
}

# =====================================
# json_delete_site_key: Delete entire .site["domain"]
# Parameters:
#   $1 - domain
#   $2 - file (optional)
# =====================================
json_delete_site_key() {
  local domain="$1"
  local file="${2:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  local path=".site[\"$domain\"]"
  json_delete_key "$path"
}

# =============================================
# 🔐 json_set_site_value_encrypted – Set encrypted value into .config.json
# ---------------------------------------------
# Parameters:
#   $1 - domain (site key)
#   $2 - key (e.g. db_pass)
#   $3 - plain-text value
# =============================================
json_set_site_value_encrypted() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local file="${4:-$JSON_CONFIG_FILE}"
  local keyfile="$BASE_DIR/.secret_key"

  if [[ -z "$domain" || -z "$key" || -z "$value" ]]; then
    print_and_debug error "❌ Missing param: domain/key/value in json_set_site_value_encrypted"
    return 1
  fi

  # Tự động tạo file key nếu chưa có
  if [[ ! -f "$keyfile" ]]; then
    print_msg warning "🔐 No secret key found. Generating new key at $keyfile"
    openssl rand -hex 32 > "$keyfile"
  fi

  local encrypted
  encrypted="ENC::$(echo -n "$value" | openssl enc -aes-256-cbc -a -salt -pass file:"$keyfile" 2>/dev/null)"

  local json_path=".site[\"$domain\"].$key"
  json_set_string_value "$json_path" "$encrypted" "$file"
}


# =============================================
# 🔓 json_get_site_value_decrypted – Decrypt value from .config.json
# ---------------------------------------------
# Parameters:
#   $1 - domain (site key)
#   $2 - key (default: db_pass)
#   $3 - file (optional)
# =============================================
json_get_site_value_decrypted() {
  local domain="$1"
  local key="${2:-db_pass}"
  local file="${3:-$JSON_CONFIG_FILE}"
  local keyfile="$BASE_DIR/.secret_key"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in json_get_site_value_decrypted"
    return 1
  fi

  local encrypted
  encrypted=$(json_get_site_value "$domain" "$key" "$file")

  if [[ "$encrypted" =~ ^ENC:: ]]; then
    local enc_data="${encrypted#ENC::}"
    # Tự động tạo file key nếu chưa có (tránh lỗi khi người dùng xóa nhầm)
    if [[ ! -f "$keyfile" ]]; then
      print_msg warning "🔐 Secret key file not found. Regenerating: $keyfile"
      openssl rand -hex 32 > "$keyfile"
    fi
    echo "$enc_data" | openssl enc -aes-256-cbc -a -d -salt -pass file:"$keyfile" 2>/dev/null
  else
    echo "$encrypted"
  fi
}
