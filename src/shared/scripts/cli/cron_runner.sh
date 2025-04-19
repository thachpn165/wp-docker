#!/bin/bash
# === Auto-detect BASE_DIR & load configuration ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        load_config_file
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$CORE_DIR/crons/cron_letsencrypt_renew.sh"

# === Xử lý lệnh truyền vào ===
case "$1" in
letsencrypt_renew)
    cron_letsencrypt_renew
    ;;
all)
    cron_letsencrypt_renew
    # gọi thêm các cron khác nếu có, ví dụ:
    # cron_backup_auto
    ;;
*)
    echo "⚙️  Usage: $0 {letsencrypt_renew|all}" >&2
    exit 1
    ;;
esac
