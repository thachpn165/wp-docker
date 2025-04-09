#!/bin/bash

# =============================================
# JSON Utility Functions - Used across project
# =============================================

# File cấu hình mặc định
JSON_CONFIG_FILE="$BASE_DIR/.config.json"

# Ensure config file exists
json_create_if_not_exists() {
  local file="${1:-$JSON_CONFIG_FILE}"
  if [[ ! -f "$file" ]]; then
    echo "{}" > "$file"
    debug_log "Created new JSON config file: $file"
  fi
}

# Get a value from a JSON file by key path
# Usage: json_get_value ".site[\"example.com\"].MYSQL_USER"
json_get_value() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  local value
  value=$(jq -r "$key" "$file" 2>/dev/null)
  debug_log "json_get_value: file=$file key=$key value=$value"
  echo "$value"
}

# Set a value in a JSON file by key path
# Usage: json_set_value ".site[\"example.com\"].MYSQL_USER" "wpuser"
json_set_value() {
  local key="$1"
  local value="$2"
  local file="${3:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  local tmp_file
  tmp_file=$(mktemp)
  if jq "$key = \"$value\"" "$file" > "$tmp_file"; then
    mv "$tmp_file" "$file"
    debug_log "json_set_value: file=$file key=$key value=$value"
  else
    debug_log "json_set_value ERROR: Failed to set $key in $file"
    rm -f "$tmp_file"
  fi
}

# Delete a key from the JSON file
# Usage: json_delete_key ".site[\"example.com\"]"
json_delete_key() {
  local key="$1"
  local domain
  domain=$(echo "$key" | sed -E 's/.*\[\"(.*)\"\].*/\1/')

  local tmp_file
  tmp_file=$(mktemp)
  jq "del($key)" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"

  # Nếu key .site["domain"] còn tồn tại nhưng là {}, thì xoá luôn key đó
  if jq -e ".site[\"$domain\"] | type == \"object\" and (keys | length == 0)" "$JSON_CONFIG_FILE" > /dev/null; then
    jq "del(.site[\"$domain\"])" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"
    debug_log "[json_delete_key] Removed empty domain entry: $domain"
  fi
}

# Check if a key exists in the JSON file
# Usage: json_key_exists ".site[\"example.com\"].MYSQL_USER"
json_key_exists() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  if jq -e "$key != null" "$file" >/dev/null 2>&1; then
    debug_log "json_key_exists: file=$file key=$key -> exists"
    return 0
  else
    debug_log "json_key_exists: file=$file key=$key -> not found"
    return 1
  fi
}

# =============================================
# JSON Site Utilities – Manage .site["$domain"]
# =============================================

# 📄 Get a value inside .site["$domain"]
json_get_site_value() {
  local domain="$1"
  local key="$2"
  local file="${3:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" ]]; then
    print_and_debug error "❌ Missing parameters in json_get_site_value(domain, key)"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_get_value "$path" "$file"
}

# 📝 Set a value inside .site["$domain"]
json_set_site_value() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local file="${4:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" || -z "$value" ]]; then
    print_and_debug error "❌ Missing parameters in json_set_site_value(domain, key, value)"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_set_value "$path" "$value" "$file"
}

# ❌ Delete a specific field from .site["$domain"]
json_delete_site_field() {
  local domain="$1"
  local key="$2"
  local file="${3:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" || -z "$key" ]]; then
    print_and_debug error "❌ Missing parameters in json_delete_site_field(domain, key)"
    return 1
  fi

  local path=".site[\"$domain\"].$key"
  json_delete_key "$path"
}

# 🧹 Delete entire .site["$domain"]
json_delete_site_key() {
  local domain="$1"
  local file="${2:-$JSON_CONFIG_FILE}"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing parameter in json_delete_site_key(domain)"
    return 1
  fi

  local path=".site[\"$domain\"]"
  json_delete_key "$path"
}