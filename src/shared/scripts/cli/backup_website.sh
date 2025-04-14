#!/bin/bash

# =====================================
# 📁 backup_cli_file – CLI wrapper to backup only WordPress files
# Parameters:
#   --domain=<domain>
# =====================================
backup_cli_file() {
  local domain
  domain=$(_parse_params "--domain" "$@")

  if [[ -z "$domain" || "$domain" == "--domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  backup_file_logic "$domain"
}

# =====================================
# 🔄 backup_cli_backup_web – Full website backup (files + db + optional rclone)
# Parameters:
#   --domain=<domain>
#   --storage=<local|cloud>
#   [--rclone_storage=<name>]
# =====================================
backup_cli_backup_web() {
  local domain storage rclone_storage

  domain=$(_parse_params "--domain" "$@")
  storage=$(_parse_params "--storage" "$@")
  rclone_storage=$(_parse_optional_params "--rclone_storage" "$@")

  if [[ -z "$domain" || "$domain" == "--domain" || -z "$storage" || "$storage" == "--storage" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain & --storage (local|cloud)"
    exit 1
  fi

  backup_logic_website "$domain" "$storage" "$rclone_storage"
}