#!/bin/bash
rclone_setup() {
  is_directory_exist "$RCLONE_CONFIG_DIR" true

  # Check if rclone is installed
  if ! command -v rclone &>/dev/null; then
    print_and_debug warning "$WARNING_RCLONE_NOT_INSTALLED"
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install rclone || {
        print_and_debug error "$ERROR_RCLONE_INSTALL_FAILED"
        return 1
      }
    else
      safe_curl https://rclone.org/install.sh | sudo bash || {
        print_and_debug error "$ERROR_RCLONE_INSTALL_FAILED"
        return 1
      }
    fi
    print_msg success "$SUCCESS_RCLONE_INSTALLED"
  else
    print_msg success "$SUCCESS_RCLONE_ALREADY_INSTALLED"
  fi

  print_msg run "$INFO_RCLONE_SETUP_START"

  # Create config file if missing
  if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
    local create_msg
    create_msg="$(printf "$INFO_RCLONE_CREATING_CONF" "$RCLONE_CONFIG_FILE")"
    print_msg info "$create_msg"
    touch "$RCLONE_CONFIG_FILE" || {
      print_and_debug error "$(printf "$ERROR_RCLONE_CREATE_CONF_FAILED" "$RCLONE_CONFIG_FILE")"
      return 1
    }
  fi

  # === Prompt storage name ===
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

    # === Prompt storage type ===
    print_msg info "$INFO_RCLONE_SELECT_STORAGE_TYPE"
    echo -e "  ${GREEN}[1]${NC} Google Drive"
    echo -e "  ${GREEN}[2]${NC} Dropbox"
    echo -e "  ${GREEN}[3]${NC} S3 Storage"
    echo -e "  ${GREEN}[4]${NC} Exit"

    local choice
    choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION")

    case "$choice" in
    1) STORAGE_TYPE="drive" ;;
    2) STORAGE_TYPE="dropbox" ;;
    3) STORAGE_TYPE="s3" ;;
    4)
      print_msg cancel "$MSG_EXITING"
      return
      ;;
    *)
      print_msg error "$ERROR_SELECT_OPTION_INVALID"
      continue
      ;;
    esac

    break
  done

  print_msg step "$(printf "$STEP_RCLONE_SETTING_UP" "$STORAGE_NAME")"

  {
    echo "[$STORAGE_NAME]"
    echo "type = $STORAGE_TYPE"
  } >>"$RCLONE_CONFIG_FILE"

  # Configure based on storage type
  if [[ "$STORAGE_TYPE" == "drive" ]]; then
    print_msg recommend "$INFO_RCLONE_DRIVE_AUTH_GUIDE"
    AUTH_JSON=$(get_input_or_test_value "🔑 $PROMPT_RCLONE_DRIVE_PASTE_TOKEN")
    echo "token = $AUTH_JSON" >>"$RCLONE_CONFIG_FILE"
    print_msg success "$SUCCESS_RCLONE_DRIVE_SETUP"

  elif [[ "$STORAGE_TYPE" == "dropbox" ]]; then
    echo "token = $(rclone authorize dropbox)" >>"$RCLONE_CONFIG_FILE"

  elif [[ "$STORAGE_TYPE" == "s3" ]]; then
    ACCESS_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_ACCESS_KEY")
    SECRET_KEY=$(get_input_or_test_value "$PROMPT_RCLONE_S3_SECRET_KEY")
    REGION=$(get_input_or_test_value "$PROMPT_RCLONE_S3_REGION")

    {
      echo "provider = AWS"
      echo "access_key_id = $ACCESS_KEY"
      echo "secret_access_key = $SECRET_KEY"
      echo "region = $REGION"
    } >>"$RCLONE_CONFIG_FILE"
  fi

  print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_ADDED" "$STORAGE_NAME")"
  print_msg info "📄 Config: $BASE_DIR/$RCLONE_CONFIG_FILE"
  print_msg info "📄 Config: $BASE_DIR/$RCLONE_CONFIG_FILE"
}
