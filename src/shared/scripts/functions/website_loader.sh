#!/usr/bin/env bash
# ==========================================
# 📦 website_loader.sh
# Load all website management related functions
# ==========================================

# Ensure config.sh is already loaded before this script is called!
if [[ -z "$FUNCTIONS_DIR" ]]; then
  echo "❌ FUNCTIONS_DIR not defined. Please load config.sh first." >&2
  exit 1
fi

# Load all .sh files in website/
for f in "$FUNCTIONS_DIR/website/"*.sh; do
  [[ -f "$f" ]] && source "$f"
done

# Load PHP version chooser
source "$FUNCTIONS_DIR/php/php_choose_version.sh"
