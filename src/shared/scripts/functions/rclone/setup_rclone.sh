#!/bin/bash

# Function to setup Rclone
rclone_setup() {
  is_directory_exist "$RCLONE_CONFIG_DIR" || mkdir -p "$RCLONE_CONFIG_DIR"

  if ! command -v rclone &> /dev/null; then
    print_and_debug warning "$WARNING_RCLONE_NOT_INSTALLED"

    if [[ "$(uname)" == "Darwin" ]]; then
      brew install rclone || {
        print_and_debug error "$ERROR_RCLONE_INSTALL_FAILED"
        return 1
      }
    else
      curl https://rclone.org/install.sh | sudo bash || {
        print_and_debug error "$ERROR_RCLONE_INSTALL_FAILED"
        return 1
      }
    fi

    print_msg success "$SUCCESS_RCLONE_INSTALLED"
  else
    print_msg success "$SUCCESS_RCLONE_ALREADY_INSTALLED"
  fi

  print_msg run "$INFO_RCLONE_SETUP_START"

  if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
    local create_msg
    create_msg="$(printf "$INFO_RCLONE_CREATING_CONF" "$RCLONE_CONFIG_FILE")"
    print_msg info "$create_msg"
    touch "$RCLONE_CONFIG_FILE" || {
      print_and_debug error "$(printf "$ERROR_RCLONE_CREATE_CONF_FAILED" "$RCLONE_CONFIG_FILE")"
      return 1
    }
  fi

  while true; do
    STORAGE_NAME=$(get_input_or_test_value "📌 $PROMPT_ENTER_STORAGE_NAME" "$TEST_STORAGE_NAME")
    STORAGE_NAME=$(echo "$STORAGE_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -cd '[:alnum:]_-')

    debug_log "[RCLONE] Checking if storage name exists: $STORAGE_NAME"

    if grep -q "^\[$STORAGE_NAME\]" "$RCLONE_CONFIG_FILE"; then
      print_msg error "$(printf "$ERROR_RCLONE_STORAGE_EXISTED" "$STORAGE_NAME")"
    else
      break
    fi
  done

  print_msg info "$INFO_RCLONE_SELECT_STORAGE_TYPE"
  echo -e "  ${GREEN}[1]${NC} Google Drive"
  echo -e "  ${GREEN}[2]${NC} Dropbox"
  echo -e "  ${GREEN}[3]${NC} AWS S3"
  echo -e "  ${GREEN}[4]${NC} DigitalOcean Spaces"
  echo -e "  ${GREEN}[5]${NC} Thoát"

  choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION" "$TEST_STORAGE_CHOICE")

  case "$choice" in
    1) STORAGE_TYPE="drive" ;;
    2) STORAGE_TYPE="dropbox" ;;
    3|4) STORAGE_TYPE="s3" ;;
    5) print_msg cancel "$MSG_EXITING"; return ;;
    *) print_msg error "$ERROR_SELECT_OPTION_INVALID"; return ;;
  esac

  debug_log "[RCLONE] Storage name: $STORAGE_NAME"
  debug_log "[RCLONE] Storage type: $STORAGE_TYPE"

  print_msg step "$(printf "$STEP_RCLONE_SETTING_UP" "$STORAGE_NAME")"

  {
    echo "[$STORAGE_NAME]"
    echo "type = $STORAGE_TYPE"
  } >> "$RCLONE_CONFIG_FILE"

  if [[ "$STORAGE_TYPE" == "drive" ]]; then
    print_msg recommend "$INFO_RCLONE_DRIVE_AUTH_GUIDE"
    AUTH_JSON=$(get_input_or_test_value "🔑 $PROMPT_RCLONE_DRIVE_PASTE_TOKEN" "$TEST_RCLONE_AUTH_JSON")
    echo "token = $AUTH_JSON" >> "$RCLONE_CONFIG_FILE"
    print_msg success "$SUCCESS_RCLONE_DRIVE_SETUP"

  elif [[ "$STORAGE_TYPE" == "dropbox" ]]; then
    echo "token = $(rclone authorize dropbox)" >> "$RCLONE_CONFIG_FILE"

  elif [[ "$STORAGE_TYPE" == "s3" ]]; then
    ACCESS_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_ACCESS_KEY" "$TEST_RCLONE_ACCESS_KEY")
    SECRET_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_SECRET_KEY" "$TEST_RCLONE_SECRET_KEY")
    REGION=$(get_input_or_test_value "$PROMPT_RCLONE_S3_REGION" "$TEST_RCLONE_REGION")

    {
      echo "provider = AWS"
      echo "access_key_id = $ACCESS_KEY"
      echo "secret_access_key = $SECRET_KEY"
      echo "region = $REGION"
    } >> "$RCLONE_CONFIG_FILE"
  fi

  print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_ADDED" "$STORAGE_NAME")"
  print_msg info "📄 Config: $BASE_DIR/$RCLONE_CONFIG_FILE"
}

# Do not execute function by default when calling script
