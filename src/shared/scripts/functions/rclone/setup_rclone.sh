setup_storage_type() {
  local config=""
  case "$STORAGE_TYPE" in
  drive)
    # Hiển thị hướng dẫn cho Google Drive
    print_msg recommend "$INFO_RCLONE_DRIVE_AUTH_GUIDE" >&2
    AUTH_JSON=$(get_input_or_test_value "🔑 $PROMPT_RCLONE_PASTE_TOKEN")
    if [[ -z "$AUTH_JSON" ]]; then
      print_msg error "$ERROR_RCLONE_TOKEN_CANNOT_EMPTY" >&2
      return 1
    fi
    config="token = $AUTH_JSON"
    ;;
  dropbox)
    # Hiển thị hướng dẫn cho Dropbox
    print_msg recommend "$INFO_RCLONE_DROPBOX_AUTH_GUIDE" >&2
    AUTH_JSON=$(get_input_or_test_value "🔑 $PROMPT_RCLONE_PASTE_TOKEN")
    if [[ -z "$AUTH_JSON" ]]; then
      print_msg error "$ERROR_RCLONE_TOKEN_CANNOT_EMPTY" >&2
      return 1
    fi
    config="token = $AUTH_JSON"
    ;;
  s3)
    # Thiết lập thông tin cho S3
    ACCESS_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_ACCESS_KEY")
    SECRET_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_SECRET_KEY")
    REGION=$(get_input_or_test_value "$PROMPT_RCLONE_S3_REGION")
    if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$REGION" ]]; then
      print_msg error "$ERROR_MISSING_S3_CREDENTIALS" >&2
      return 1
    fi
    config="provider = AWS\naccess_key_id = $ACCESS_KEY\nsecret_access_key = $SECRET_KEY\nregion = $REGION"
    ;;
  *)
    
    print_msg error "❌ Invalid storage type: $STORAGE_TYPE" >&2
    return 1
    ;;
  esac
  echo -e "$config"
}

rclone_setup() {
  _is_directory_exist "$RCLONE_CONFIG_DIR" true

  # === Ensure rclone is installed ===
  if ! command -v rclone &>/dev/null; then
    print_and_debug warning "$WARNING_RCLONE_NOT_INSTALLED"

    if [[ "$(uname)" == "Darwin" ]]; then
      if ! brew install rclone; then
        print_and_debug error "❌ Failed to install rclone via Homebrew. Please check your Homebrew setup."
        return 1
      fi
    else
      if ! safe_curl https://rclone.org/install.sh | sudo bash; then
        print_and_debug error "❌ Failed to install rclone via install script. Please check your network or permissions."
        return 1
      fi
    fi
    print_msg success "$SUCCESS_RCLONE_INSTALLED"
  else
    print_msg success "$SUCCESS_RCLONE_ALREADY_INSTALLED"
  fi

  print_msg run "$INFO_RCLONE_SETUP_START"

  # === Ensure config file exists ===
  if ! _is_file_exist "$RCLONE_CONFIG_FILE"; then
    print_msg info "$(printf "$INFO_RCLONE_CREATING_CONF" "$RCLONE_CONFIG_FILE")"
    touch "$RCLONE_CONFIG_FILE" || {
      print_and_debug error "$(printf "$ERROR_RCLONE_CREATE_CONF_FAILED" "$RCLONE_CONFIG_FILE")"
      return 1
    }
  fi

  # === Prompt for storage name ===
  while true; do
    STORAGE_NAME=$(get_input_or_test_value "📌 $PROMPT_ENTER_STORAGE_NAME")
    STORAGE_NAME=$(echo "$STORAGE_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -cd '[:alnum:]_-')

    if [[ -z "$STORAGE_NAME" ]]; then
      print_msg warning "$WARNING_STORAGE_NAME_EMPTY"
      continue
    fi

    if grep -q "^\[$STORAGE_NAME\]" "$RCLONE_CONFIG_FILE"; then
      print_msg error "$(printf "$ERROR_RCLONE_STORAGE_EXISTED" "$STORAGE_NAME")"
      continue
    fi

    break
  done

  # === Prompt storage type ===
  print_msg info "$INFO_RCLONE_SELECT_STORAGE_TYPE"
  echo -e "  ${GREEN}[1]${NC} Google Drive"
  echo -e "  ${GREEN}[2]${NC} Dropbox"
  echo -e "  ${GREEN}[3]${NC} S3 Storage"
  echo -e "  ${GREEN}[4]${NC} Exit"

  local choice
  while true; do
    choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION")
    case "$choice" in
    1)
      STORAGE_TYPE="drive"
      break
      ;;
    2)
      STORAGE_TYPE="dropbox"
      break
      ;;
    3)
      STORAGE_TYPE="s3"
      break
      ;;
    4)
      print_msg cancel "$MSG_EXITING"
      return
      ;;
    *) print_msg error "$ERROR_SELECT_OPTION_INVALID" ;;
    esac
  done

  print_msg step "$(printf "$STEP_RCLONE_SETTING_UP" "$STORAGE_NAME")"

  # === Build config block ===
  local storage_config
  storage_config=$(setup_storage_type) || {
    print_msg error "❌ Failed to configure storage type: $STORAGE_TYPE"
    return 1
  }

  local config_block="[$STORAGE_NAME]\ntype = $STORAGE_TYPE\n$storage_config"

  # === Write config ===
  if ! echo -e "$config_block" >>"$RCLONE_CONFIG_FILE"; then
    print_and_debug error "❌ Failed to write to rclone config file: $RCLONE_CONFIG_FILE"
    return 1
  fi
  print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_ADDED" "$STORAGE_NAME")"
  print_msg info "📄 Config: $BASE_DIR/$RCLONE_CONFIG_FILE"
}
