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
    echo "[TEST_MODE] Selected PHP version: $REPLY"
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

  sleep 0.2
  echo ""
  php_index=$(get_input_or_test_value "$MSG_SELECT_OPTION" "${TEST_PHP_INDEX:-0}")

  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || (( php_index < 0 || php_index >= ${#PHP_VERSIONS[@]} )); then
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi

  REPLY="${PHP_VERSIONS[$php_index]}"
}
