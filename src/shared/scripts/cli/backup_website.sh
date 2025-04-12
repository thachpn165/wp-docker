#!/bin/bash
backup_cli_file() {
  local domain
  domain=$(_parse_params "--domain" "$@")
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  backup_file_logic "$domain"
}

backup_cli_backup_web() {
  local domain
  local storage
  local rclone_storage

  # parse params
  domain=$(_parse_params "--domain" "$@")
  storage=$(_parse_params "--storage" "$@")
  rclone_storage=$(_parse_optional_params "--rclone_storage" "$@")

  if [[ -z "$domain" || "$domain" == "--domain" || -z "$storage" || "$storage" == "--storage" ]]; then
    #echo "${CROSSMARK} Missing parameters. Usage:"
    print_msg error "$ERROR_MISSING_PARAM: --domain & --storage(local, cloud)"
    exit 1
  fi

  # Execute the backup logic function
  if [[ $? -eq 0 ]]; then
    backup_logic_website "$domain" "$storage" "$rclone_storage"
  fi
}
