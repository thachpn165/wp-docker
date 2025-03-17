#!/bin/bash
SITES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../sites" && pwd)"

echo -e "\033[1;34m📋 Danh sách các website WordPress:\033[0m"
ls "$SITES_DIR"
