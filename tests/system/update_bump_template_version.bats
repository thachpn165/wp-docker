#!/usr/bin/env bats

setup() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../src" && pwd)"

    # Giả lập dữ liệu .template_version và changelog (dữ liệu thật trong hệ thống)
    mkdir -p "$PROJECT_DIR/shared/templates"
    echo "1.0.6" > "$PROJECT_DIR/shared/templates/.template_version"
    echo "# TEMPLATE CHANGELOG" > "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
}

teardown() {
    # Khôi phục lại version cũ sau test (tuỳ chọn nếu cần giữ môi trường)
    echo "1.0.6" > "$PROJECT_DIR/shared/templates/.template_version"
    echo "# TEMPLATE CHANGELOG" > "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
}

@test "Auto bump template version increases correctly (real script)" {
    run bash "$PROJECT_DIR/shared/scripts/tools/template_bump_version.sh" --auto
    [ "$status" -eq 0 ]

    run cat "$PROJECT_DIR/shared/templates/.template_version"
    [ "$output" = "1.0.7" ]
}

@test "Changelog entry is added after bump (real script)" {
    bash "$PROJECT_DIR/shared/scripts/tools/template_bump_version.sh" --auto

    run grep "## 1.0.7" "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
    [ "$status" -eq 0 ]

    run grep "- 🤖 Auto bump version from CI" "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
    [ "$status" -eq 0 ]
}
