#!/bin/bash
# ==================================================
# File: core_lang.sh
# Description: Functions to manage system language settings, including converting language codes, 
#              changing the system language, listing available languages, and retrieving the current language.
# Functions:
#   - core_lang_convert: Convert a language code to a human-readable label.
#       Parameters:
#           $1 - lang_code: The language code (e.g., en, vi, ja, ...).
#   - core_lang_change_logic: Change the system language and save it to .config.json.
#       Parameters:
#           $1 - lang_code: The language code to set (e.g., en, vi, ja, ...).
#   - core_lang_change_prompt: Prompt the user to select a language from the available options.
#       Parameters: None.
#   - core_lang_list_logic: List all available languages with their codes and labels.
#       Parameters: None.
#   - core_lang_get_logic: Retrieve the current language from the configuration.
#       Parameters: None.
# ==================================================

core_lang_convert() {
  local lang_code="$1"
  local lang_name

  case "$lang_code" in
  "en") lang_name="$LABEL_LANG_EN" ;;
  "vi") lang_name="$LABEL_LANG_VI" ;;
  "ja") lang_name="$LABEL_LANG_JA" ;;
  "zh") lang_name="$LABEL_LANG_ZH" ;;
  "ko") lang_name="$LABEL_LANG_KO" ;;
  "es") lang_name="$LABEL_LANG_ES" ;;
  "de") lang_name="$LABEL_LANG_DE" ;;
  "fr") lang_name="$LABEL_LANG_FR" ;;
  "ru") lang_name="$LABEL_LANG_RU" ;;
  "id") lang_name="$LABEL_LANG_ID" ;;
  "th") lang_name="$LABEL_LANG_TH" ;;
  "my") lang_name="$LABEL_LANG_MY" ;;
  "tw") lang_name="$LABEL_LANG_TW" ;;
  *) lang_name="Unknown" ;;
  esac

  echo "$lang_name"
}

core_lang_change_logic() {
  local lang_code="$1"

  if [[ -z "$lang_code" ]]; then
    print_and_debug error "❌ Missing language code"
    return 1
  fi

  local valid=false
  for lang in "${LANG_LIST[@]}"; do
    if [[ "$lang_code" == "$lang" ]]; then
      valid=true
      break
    fi
  done

  if [[ "$valid" == true ]]; then
    json_set_value '.core.lang' "$lang_code"
    print_msg success "$SUCCESS_LANG_CODE_UPDATED: $lang_code"
  else
    print_and_debug error "$ERROR_LANG_SET_FAILED: $lang_code"
    return 1
  fi
}

core_lang_change_prompt() {
  echo -e "\n🌐 $PROMPT_SELECT_LANGUAGE"
  PS3="$PROMPT_SELECT_OPTION "

  local options=()
  for lang in "${LANG_LIST[@]}"; do
    options+=("$lang")
  done

  select opt in "${options[@]}"; do
    if [[ -n "$opt" ]]; then
      core_lang_change_logic "$opt"
      break
    else
      print_and_debug error "$ERROR_SELECT_OPTION_INVALID"
    fi
  done
}

core_lang_list_logic() {
  if [[ ${#LANG_LIST[@]} -eq 0 ]]; then
    print_and_debug error "$ERROR_LANG_LIST_NOT_SET"
    return 1
  fi

  for code in "${LANG_LIST[@]}"; do
    local label
    label="$(core_lang_convert "$code")"
    echo "${YELLOW}$code${NC} - $label"
    debug_log "[core_lang_list_logic] $code - $label"
  done
}

core_lang_get_logic() {
  local lang
  lang="$(json_get_value '.core.lang')"
  if [[ -z "$lang" ]]; then
    print_msg error "$ERROR_LANG_NOT_SET"
    return 1
  fi
  core_lang_convert "$lang"
}