#!/usr/bin/env bash

# === Safe source single file ===
safe_source() {
  local file="$1"
  local full_path="$FUNCTIONS_DIR/$file"
  if [ -f "$full_path" ]; then
    source "$full_path"
  else
    echo "[WARN] Skipped missing file: $full_path"
  fi
}

# === GROUP: Core utilities ===
safe_source_group_core_utils() {
  safe_source "system_utils.sh"
  safe_source "docker_utils.sh"
  safe_source "file_utils.sh"
  safe_source "network_utils.sh"
  safe_source "ssl_utils.sh"
  safe_source "wp_utils.sh"
  safe_source "db_utils.sh"
  safe_source "website_utils.sh"
  safe_source "misc_utils.sh"
}

# === GROUP: PHP ===
safe_source_group_php() {
  safe_source "php/php_utils.sh"
  safe_source "php/php_change_version.sh"
  safe_source "php/php_choose_version.sh"
  safe_source "php/php_edit_conf.sh"
  safe_source "php/php_edit_phpini.sh"
  safe_source "php/php_get_version.sh"
  safe_source "php/php_rebuild.sh"
}

# === GROUP: NGINX ===
safe_source_group_nginx() {
  safe_source "nginx/nginx_utils.sh"
}

# === GROUP: Backup ===
safe_source_group_backup() {
  safe_source "backup-manager/backup_database.sh"
  safe_source "backup-manager/backup_files.sh"
  safe_source "backup-manager/backup_restore_functions.sh"
  safe_source "backup-manager/backup_restore_web.sh"
  safe_source "backup-manager/cleanup_backups.sh"
  safe_source "backup-scheduler/backup_runner.sh"
}

# === GROUP: Core system ===
safe_source_group_core_system() {
  safe_source "core/core_version_management.sh"
}

# === GROUP: SSL ===
safe_source_group_ssl() {
  safe_source "ssl/ssl_check_cert_status.sh"
  safe_source "ssl/ssl_edit_cert.sh"
  safe_source "ssl/ssl_generate_self_signed.sh"
  safe_source "ssl/ssl_install_letsencrypt.sh"
  safe_source "ssl/ssl_install_manual.sh"
}

# === GROUP: System Tools ===
safe_source_group_system_tools() {
  safe_source "system-tools/system-check-resources.sh"
  safe_source "system-tools/system_cleanup_docker.sh"
  safe_source "system-tools/system_manage_docker.sh"
  safe_source "system-tools/system_nginx_rebuild.sh"
}

# === GROUP: Website Management ===
safe_source_group_website() {
  safe_source "website/website_create_env.sh"
  safe_source "website/website_management_create.sh"
  safe_source "website/website_management_delete.sh"
  safe_source "website/website_management_info.sh"
  safe_source "website/website_management_list.sh"
  safe_source "website/website_management_logs.sh"
  safe_source "website/website_management_restart.sh"
  safe_source "website/website_update_site_template.sh"
}

# === LOAD ALL GROUPS ===
load_all_functions() {
  safe_source_group_core_utils
  safe_source_group_php
  safe_source_group_nginx
  safe_source_group_backup
  safe_source_group_core_system
  safe_source_group_ssl
  safe_source_group_system_tools
  safe_source_group_website
}

# === Helper: tạo tmp dir cho mock command ===
setup_tmp_dir() {
  export TEST_TMP_DIR="${BATS_TEST_DIRNAME}/../tmp"
  mkdir -p "$TEST_TMP_DIR"
}

teardown_tmp_dir() {
  [[ -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]] && rm -rf "$TEST_TMP_DIR"
}

# === Assert helper ===
assert_output_contains() {
  local expected="$1"
  [[ "$output" == *"$expected"* ]] || {
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  }
}

# === Mock command to always succeed ===
mock_run_success() {
  local cmd="$1"
  echo -e "#!/bin/bash\nexit 0" > "$TEST_TMP_DIR/$cmd"
  chmod +x "$TEST_TMP_DIR/$cmd"
  export PATH="$TEST_TMP_DIR:$PATH"
}

# === Mock command to always fail ===
mock_run_fail() {
  local cmd="$1"
  echo -e "#!/bin/bash\nexit 1" > "$TEST_TMP_DIR/$cmd"
  chmod +x "$TEST_TMP_DIR/$cmd"
  export PATH="$TEST_TMP_DIR:$PATH"
}
