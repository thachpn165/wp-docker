#!/bin/bash

# =============================================
# JSON Utility Functions - Used across project
# =============================================
# This script provides utility functions for managing JSON files using `jq`.
# Functions:
# - json_create_if_not_exists: Creates an empty JSON file if it doesn't exist. Parameters: $1 (optional file path).
# - json_get_value: Retrieves a value from a JSON file by jq path. Parameters: $1 (jq path), $2 (optional file path).
# - json_set_value: Sets a value in a JSON file by jq path. Parameters: $1 (jq path), $2 (value), $3 (optional file path).
# - json_set_string_value: Sets a string value in a JSON file by jq path. Parameters: $1 (jq path), $2 (value), $3 (optional file path).
# - json_delete_key: Deletes a key from a JSON file. Parameters: $1 (jq path).
# - json_key_exists: Checks if a key exists in a JSON file. Parameters: $1 (jq path), $2 (optional file path).
# - json_get_site_value: Retrieves a value from .site["domain"]. Parameters: $1 (domain), $2 (key), $3 (optional file path).
# - json_set_site_value: Sets a value inside .site["domain"]. Parameters: $1 (domain), $2 (key), $3 (value), $4 (optional file path).
# - json_delete_site_field: Deletes a specific key in .site["domain"]. Parameters: $1 (domain), $2 (key), $3 (optional file path).
# - json_delete_site_key: Deletes the entire .site["domain"]. Parameters: $1 (domain), $2 (optional file path).
# =============================================

JSON_CONFIG_FILE="$BASE_DIR/.config.json"

json_create_if_not_exists() {
  local file="${1:-$JSON_CONFIG_FILE}"
  if [[ ! -f "$file" ]]; then
    echo "{}" > "$file"
    debug_log "Created new JSON config file: $file"
  fi
}

json_get_value() {
  local key="$1"
  local file="${2:-$JSON_CONFIG_FILE}"
  json_create_if_not_exists "$file"
  local value
  value=$(jq -r "$key" "$file" 2>/dev/null)
  debug_log "json_get_value: file=$file key=$key value=$value"
  echo "$value"
}

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

json_delete_key() {
  local key="$1"
  local domain
  domain=$(echo "$key" | sed -E 's/.*\[\"(.*)\"\].*/\1/')

  local tmp_file
  tmp_file=$(mktemp)
  jq "del($key)" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"

  if jq -e ".site[\"$domain\"] | type == \"object\" and (keys | length == 0)" "$JSON_CONFIG_FILE" > /dev/null; then
    jq "del(.site[\"$domain\"])" "$JSON_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$JSON_CONFIG_FILE"
    debug_log "[json_delete_key] Removed empty domain entry: $domain"
  fi
}

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
