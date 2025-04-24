safe_source "$FUNCTIONS_DIR/system-tools/system_check_resources.sh"

check_resources_output=$(system_logic_check_resources)
echo "$check_resources_output"