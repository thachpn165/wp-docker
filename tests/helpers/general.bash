setup() {
  # Mock env trong mỗi test
  export BASE_DIR="/tmp/wp-docker-test"
  export PROJECT_DIR="$BASE_DIR"
  export JSON_CONFIG_FILE="$BASE_DIR/.config.json"
  export CORE_ENV="$BASE_DIR/.env"
  export LANG_LIST=("vi" "en" "fr")
  export LANG_CODE="vi"
  export TEST_MODE=true

  mkdir -p "$BASE_DIR/shared/scripts/functions/utils"
  mkdir -p "$BASE_DIR/logs"

  print_and_debug() { echo "$@"; }
  print_msg() { echo "$@"; }
  debug_log() { echo "[DEBUG] $*"; }

  # Load hàm cần test
  source "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/utils/json_utils.sh"
  source "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/core/core_lang.sh"
}