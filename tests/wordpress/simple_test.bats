#!/usr/bin/env bats

setup() {
    # Create a temporary directory
    export TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/sites/test-site"
}

teardown() {
    # Clean up
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "Simple test to check if we can create directories" {
    # Try to create a directory
    mkdir -p "$TEST_DIR/sites/test-site/wordpress"
    
    # Check if it exists
    [ -d "$TEST_DIR/sites/test-site/wordpress" ]
} 