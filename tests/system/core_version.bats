#!/usr/bin/env bats
source "${BATS_TEST_DIRNAME}/../helpers/mock_env.bash"

setup() {
  setup_env

  # Source core functions
  source "$FUNCTIONS_DIR/core/core_version_management.sh"
  source "$BATS_TEST_DIRNAME/../helpers/load_all_utils.sh"

  # Tạo version.txt hiện tại
  echo "v1.0.0" > "$BASE_DIR/version.txt"

  # 👉 File cache ban đầu chứa phiên bản cũ
  echo "v0.0.1" > "$BASE_DIR/latest_version.txt"

  # 👉 Mock file chứa phiên bản mới nhất như trên GitHub
  echo "v9.9.9" > "$BASE_DIR/mock_github_version.txt"
  export CORE_LATEST_VERSION="file://$BASE_DIR/mock_github_version.txt"

  mkdir -p "$BASE_DIR/shared/templates"
  echo "0.0.1" > "$BASE_DIR/shared/templates/.template_version"

  mkdir -p "$SITES_DIR/example-site"
  echo "0.0.0" > "$SITES_DIR/example-site/.template_version"
}


teardown() {
  rm -rf "$BASE_DIR"
}

# Hàm giả lập thời gian sửa đổi của file (hỗ trợ macOS và Linux)
set_file_mtime() {
  local file="$1"
  local seconds_ago="$2"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: dùng -v (seconds) để lùi thời gian
    timestamp=$(date -v-"$seconds_ago"S +%Y%m%d%H%M.%S)
  else
    # Linux: dùng GNU date
    timestamp=$(date -d "$seconds_ago seconds ago" +%Y%m%d%H%M.%S)
  fi

  touch -t "$timestamp" "$file"
}

@test "core_version_cache retrieves version from GitHub (mocked)" {
  rm -f "$BASE_DIR/latest_version.txt"
  echo "v9.9.9" > "$BASE_DIR/latest_version.txt"
  run core_version_cache
  [ "$status" -eq 0 ]
  [ "$output" = "v9.9.9" ]
}

@test "core_version_cache uses cached version if not expired" {
  echo "v9.9.9" > "$BASE_DIR/latest_version.txt"
  set_file_mtime "$BASE_DIR/latest_version.txt" 3600  # 1 giờ trước
  run core_version_cache
  [ "$status" -eq 0 ]
  [ "$output" = "v9.9.9" ]
}

@test "core_version_cache refreshes cache if expired" {
  echo "v0.0.1" > "$BASE_DIR/latest_version.txt"           # nội dung cũ
  echo "v9.9.9" > "$BASE_DIR/mock_github_version.txt"      # mock GitHub mới
  export CORE_LATEST_VERSION="file://$BASE_DIR/mock_github_version.txt"

  set_file_mtime "$BASE_DIR/latest_version.txt" 86400     # làm cache cũ

  run core_version_cache
  echo "DEBUG: output=$output"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "v9.9.9" ]]
}

@test "core_display_version shows latest if up to date" {
  echo "v9.9.9" > "$BASE_DIR/version.txt"
  echo "v9.9.9" > "$BASE_DIR/latest_version.txt"          # nội dung cache đã đúng
  run core_display_version
  echo "DEBUG: output=$output"
  [[ "$output" =~ "latest" ]]
}


@test "core_display_version shows warning if outdated" {
  echo "v1.0.0" > "$BASE_DIR/version.txt"
  run core_display_version
  [[ "$output" =~ "new version available" ]]
}

@test "core_check_template_version detects outdated template" {
  run core_check_template_version
  [[ "$output" =~ "OLD" ]]
}

@test "core_check_for_update detects new version" {
  echo "v1.0.0" > "$BASE_DIR/version.txt"
  run core_check_for_update
  [[ "$output" =~ "⚠️ New version available" ]]
}
