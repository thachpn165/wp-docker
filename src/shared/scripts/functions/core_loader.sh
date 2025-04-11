#!/usr/bin/env bash
# ==========================================
# 📦 backup_loader.sh
# Load all backup related functions
# ==========================================

# Ensure config.sh is already loaded before this script is called!
if [[ -z "$FUNCTIONS_DIR" ]]; then
  echo "${CROSSMARK} FUNCTIONS_DIR not defined. Please load config.sh first." >&2
  exit 1
fi

# Load all .sh files in website/
for f in "$FUNCTIONS_DIR/core/"*.sh; do
# shellcheck source=/dev/null
  [[ -f "$f" ]] && source "$f"
done
