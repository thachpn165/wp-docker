#!/usr/bin/env bats

setup() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_DIR="$TEST_DIR/src"

    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../src" && pwd)"

    mkdir -p "$PROJECT_DIR/shared/templates"
    mkdir -p "$PROJECT_DIR/shared/scripts/tools"
    mkdir -p "$PROJECT_DIR/shared/config"

    cp "$SCRIPT_DIR/shared/scripts/tools/template_bump_version.sh" "$PROJECT_DIR/shared/scripts/tools/"
    chmod +x "$PROJECT_DIR/shared/scripts/tools/template_bump_version.sh"

    # Giả lập config.sh
    cat > "$PROJECT_DIR/shared/config/config.sh" << EOF
export BASE_DIR="$PROJECT_DIR"
export TEMPLATE_VERSION_FILE="\$BASE_DIR/shared/templates/.template_version"
export TEMPLATE_CHANGELOG_FILE="\$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
EOF

    # Giả lập dữ liệu .template_version và changelog
    echo "1.0.6" > "$PROJECT_DIR/shared/templates/.template_version"
    echo "# TEMPLATE CHANGELOG" > "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
}

teardown() {
    [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "Auto bump template version increases correctly (real script copy)" {
    run env PROJECT_DIR="$PROJECT_DIR" bash "$PROJECT_DIR/shared/scripts/tools/template_bump_version.sh" --auto
    [ "$status" -eq 0 ]

    run cat "$PROJECT_DIR/shared/templates/.template_version"
    [ "$output" = "1.0.7" ]
}

@test "Changelog entry is added after bump (real script copy)" {
    bash "$PROJECT_DIR/shared/scripts/tools/template_bump_version.sh" --auto

    # Debug: In ra nội dung changelog sau khi bump
    echo ">>> Changelog content after bump:"
    cat "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"

    run grep "## 1.0.7" "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
    [ "$status" -eq 0 ]

    run grep "- 🤖 Auto bump version from CI" "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"
}

