# This function, `php_choose_version`, allows the user to select a PHP version from a list of supported versions.
# The list of PHP versions is read from a file named `php_versions.txt` located in the `$BASE_DIR` directory.
#
# Steps performed by the function:
# 1. Checks if the `php_versions.txt` file exists. If not, it logs an error message and exits with a non-zero status.
# 2. Reads the PHP versions from the file into an array `PHP_VERSIONS`. If the file is empty, it logs an error and exits.
# 3. If `TEST_MODE` is enabled, it selects a PHP version automatically (using `TEST_PHP_VERSION` or the first version in the list) and logs the selection.
# 4. If not in `TEST_MODE`, it displays the list of available PHP versions to the user, along with recommendations and warnings.
# 5. Prompts the user to select a PHP version by entering the corresponding index. Validates the input to ensure it is a valid index.
# 6. If the input is valid, it sets the selected PHP version in the `REPLY` variable. Otherwise, it logs an error and exits.
#
# Dependencies:
# - `print_msg`: A function used to log messages with different levels (e.g., error, info, warning).
# - `get_input_or_test_value`: A function used to get user input or a test value in `TEST_MODE`.
# - `debug_log`: A function used to log debug messages.
#
# Global Variables:
# - `$BASE_DIR`: The base directory where the `php_versions.txt` file is located.
# - `$TEST_MODE`: A flag indicating whether the function is running in test mode.
# - `$TEST_PHP_VERSION`: The PHP version to select automatically in test mode.
# - `$TEST_PHP_INDEX`: The index of the PHP version to select automatically in test mode.
# - `$MSG_NOT_FOUND`, `$ERROR_PHP_LIST_EMPTY`, `$MSG_PHP_LIST_SUPPORTED`, `$TIPS_PHP_RECOMMEND_VERSION`,
#   `$WARNING_PHP_ARM_TITLE`, `$WARNING_PHP_ARM_LINE1` to `$WARNING_PHP_ARM_LINE5`, `$MSG_SELECT_OPTION`,
#   `$ERROR_SELECT_OPTION_INVALID`: Predefined messages used for logging and user prompts.
#
# Output:
# - Sets the selected PHP version in the `REPLY` variable if successful.
# - Logs appropriate messages for errors, warnings, and recommendations.
php_choose_version() {
  local PHP_VERSION_FILE="$BASE_DIR/php_versions.txt"

  if [[ ! -f "$PHP_VERSION_FILE" ]]; then
    print_msg error "$MSG_NOT_FOUND: $PHP_VERSION_FILE"
    return 1
  fi

  PHP_VERSIONS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && PHP_VERSIONS+=("$line")
  done < "$PHP_VERSION_FILE"

  if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
    print_msg error "$ERROR_PHP_LIST_EMPTY"
    print_msg tip "wpdocker php get"
    return 1
  fi

  if [[ "$TEST_MODE" == true ]]; then
    REPLY="${TEST_PHP_VERSION:-${PHP_VERSIONS[0]}}"
    debug_log "[TEST_MODE] Selected PHP version: $REPLY"
    return 0
  fi

  print_msg info "$MSG_PHP_LIST_SUPPORTED"
  for i in "${!PHP_VERSIONS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
  done

  print_msg recommend "$TIPS_PHP_RECOMMEND_VERSION"
  print_msg warning "$WARNING_PHP_ARM_TITLE"
  print_msg warning "$WARNING_PHP_ARM_LINE1"
  print_msg warning "$WARNING_PHP_ARM_LINE2"
  print_msg warning "$WARNING_PHP_ARM_LINE3"
  print_msg warning "$WARNING_PHP_ARM_LINE4"
  print_msg warning "$WARNING_PHP_ARM_LINE5"

  echo ""
  sleep 0.2
  php_index=$(get_input_or_test_value "$MSG_SELECT_OPTION" "${TEST_PHP_INDEX:-0}")

  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || (( php_index < 0 || php_index >= ${#PHP_VERSIONS[@]} )); then
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi

  REPLY="${PHP_VERSIONS[$php_index]}"
}