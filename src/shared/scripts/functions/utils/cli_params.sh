# ========================================================================
# CLI Parameters Functions
# Used to parse command line arguments and options
# ========================================================================

# =====================================
# _parse_params: Parse required CLI parameter in the form param=value
# Parameters:
#   $1 - param_name: Name of the required parameter to look for
# Usage:
#   _parse_params "--domain" "$@"
# Output:
#   Echoes value if found, errors if not found
# =====================================
_parse_params() {
  local param_name="$1"
  local param_value=""

  # Check if param name is missing
  if [[ -z "$param_name" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: $param_name"
    return 1
  fi

  # Loop through arguments and extract matching param
  for arg in "$@"; do
    case $arg in
      "${param_name}"=*) param_value="${arg#*=}" ;;
    esac
  done

  # Return the value if valid
  echo "$param_value"
}

# =====================================
# _parse_optional_params: Parse optional CLI parameter in the form param=value
# Parameters:
#   $1 - param_name: Name of the optional parameter to look for
# Usage:
#   _parse_optional_params "--env" "$@"
# Output:
#   Echoes value if found, empty string otherwise
# =====================================
_parse_optional_params() {
  local param_name="$1"
  local param_value=""

  # Check if param name is missing
  if [[ -z "$param_name" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: $param_name"
    exit 1
  fi

  # Loop through arguments and extract matching param
  for arg in "$@"; do
    case $arg in
      "${param_name}"=*) param_value="${arg#*=}" ;;
    esac
  done

  # Return the value (can be empty)
  echo "$param_value"
}