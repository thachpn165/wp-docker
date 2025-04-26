#!/bin/bash
# ==================================================
# File: core_init_config.sh
# Description: Functions to initialize the core configuration, including setting default 
#              values for release channels, installed versions, and language settings.
# Functions:
#   - core_init_config: Initialize core configuration with default values.
#       Parameters: None.
# ==================================================

core_init_config() {
  # Step 1: Create .config.json if not exists
  json_create_if_not_exists

  # Step 2: Initialize default values for `core` group

  # 2.1 Set core.channel if not set
  if ! json_key_exists '.core.channel'; then
    echo -e "$PROMPT_SELECT_CHANNEL"
    PS3="$(echo -e "$PROMPT_SELECT_OPTION") "
    select opt in "official" "nightly" "dev"; do
      case "$opt" in
        official|nightly|dev)
          core_set_channel "$opt"
          print_msg success "$(printf "$SUCCESS_CORE_CHANNEL_SET" "$opt" "$JSON_CONFIG_FILE")"
          break
          ;;
        *)
          print_msg error "$ERROR_SELECT_OPTION_INVALID"
          ;;
      esac
    done
  else
    debug_log "[core_init_config] core.channel already set: $(core_channel_get)"
  fi

  # 2.2 Set core.installed_version if not set
  if ! json_key_exists '.core.installed_version'; then
    local default_version
    if core_is_dev_mode; then
      default_version="dev"
    else
      default_version="0.0.0"
    fi
    core_set_installed_version "$default_version"
    debug_log "[core_init_config] Initialized core.installed_version = $default_version"
  fi

  # Step 3: Set default language if not set
  if ! json_key_exists '.core.lang'; then
    core_lang_change_prompt
  else
    debug_log "[core_init_config] Language already set: $(json_get_value '.core.lang')"
  fi

  # Step 4: (Future) Add other default core settings here
  # json_set_value '.core.debug_mode' false
  # json_set_value '.core.auto_update' true
}