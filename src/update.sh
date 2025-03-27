#!/bin/bash

# === 🧠 Tự động xác định PROJECT_DIR (gốc mã nguồn) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === ✅ Load config.sh từ PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# === ✅ Load update_core.sh để sử dụng các hàm cập nhật ===
UPDATE_CORE_FILE="$PROJECT_DIR/shared/scripts/functions/core/update_core.sh"
if [[ ! -f "$UPDATE_CORE_FILE" ]]; then
  echo "❌ Không tìm thấy update_core.sh tại: $UPDATE_CORE_FILE" >&2
  exit 1
fi
source "$UPDATE_CORE_FILE"

# === 🔄 Chạy toàn bộ quy trình cập nhật ===
core_update_system  # Gọi hàm cập nhật từ update_core.sh
