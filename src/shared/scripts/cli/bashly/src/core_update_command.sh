safe_source "$FUNCTIONS_DIR/core/core_version_management.sh"

safe_source "$FUNCTIONS_DIR/core/core_version_management.sh"

if [[ "${args[--force]}" == "1" ]]; then
    core_version_update_latest --force=1
else
    core_version_update_latest
fi
