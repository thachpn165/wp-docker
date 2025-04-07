#!/bin/bash

# Other existing functions...

core_change_lang_logic() {
  local env_file="$PROJECT_DIR/.env"

  if [[ ! -f "$env_file" ]]; then
    print_and_debug error "$ERROR_BACKUP_ENV_FILE_NOT_FOUND: $env_file"
    return 1
  fi

  print_msg info "$INFO_AVAILABLE_LANGUAGES"
  local total_options="${#LANG_LIST[@]}"
  for i in "${!LANG_LIST[@]}"; do
    echo "$((i + 1))) ${LANG_LIST[$i]}"
  done
  echo "$((total_options + 1))) Custom..."

  local choice
  choice=$(get_input_or_test_value "$PROMPT_SELECT_LANG" "${TEST_LANG_CHOICE:-1}")

  local lang_code=""
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total_options )); then
    lang_code="${LANG_LIST[$((choice - 1))]}"
  elif [[ "$choice" == "$((total_options + 1))" ]]; then
    lang_code=$(get_input_or_test_value "$PROMPT_ENTER_CUSTOM_LANG" "${TEST_LANG_CUSTOM:-en}")
  else
    print_msg error "$ERROR_INVALID_CHOICE"
    return 1
  fi

  if [[ -z "$lang_code" ]]; then
    print_msg error "$ERROR_LANG_CODE_REQUIRED"
    return 1
  fi

  # Update LANG_CODE in .env
  if grep -q "^LANG_CODE=" "$env_file"; then
    sedi "s/^LANG_CODE=.*/LANG_CODE=$lang_code/" "$env_file"
  else
    echo "LANG_CODE=$lang_code" >> "$env_file"
  fi

  print_msg success "$(printf "$SUCCESS_LANG_CODE_UPDATED" "$lang_code")"
}

# Other existing functions...
