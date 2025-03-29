#!/usr/bin/env bash

# === Load sandbox tạo môi trường test ===
load "../helpers/sandbox.bash"

setup_env() {
  # Tạo môi trường sandbox chuẩn
  create_test_sandbox

  # Bạn có thể thêm các mock biến/tệp/dummy ở đây nếu test cần
  mkdir -p "$SITES_DIR"
  mkdir -p "$RCLONE_CONFIG_DIR"
  touch "$RCLONE_CONFIG_FILE"
}
