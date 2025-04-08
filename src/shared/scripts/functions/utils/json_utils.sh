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
# Usage: json_get_value ".core.channel"
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
# Usage: json_set_value ".core.channel" "official"
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
# Usage: json_delete_key ".core.channel"
json_delete_key() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  local tmp_file
  tmp_file=$(mktemp)
  if jq "del($key)" "$file" > "$tmp_file"; then
    mv "$tmp_file" "$file"
    debug_log "json_delete_key: file=$file key=$key"
  else
    debug_log "json_delete_key ERROR: Failed to delete $key in $file"
    rm -f "$tmp_file"
  fi
}

# Check if a key exists in the JSON file
# Usage: json_key_exists ".core.channel"
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