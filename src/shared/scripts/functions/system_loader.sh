#!/bin/bash

# Load all .sh files in the functions/ssl directory
if [[ -z "$FUNCTIONS_DIR" ]]; then
  echo "${CROSSMARK} FUNCTIONS_DIR not defined. Please load config.sh first." >&2
  exit 1
fi

# Load all .sh files in website/
for f in "$FUNCTIONS_DIR/system-tools/"*.sh; do
# shellcheck source=/dev/null
  [[ -f "$f" ]] && source "$f"
done
