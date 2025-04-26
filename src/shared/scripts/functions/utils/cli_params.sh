#!/bin/bash
# ==================================================
# File: cli_params.sh
# Description: Functions to parse command-line arguments and options, including required 
#              and optional parameters in the form of param=value.
# Functions:
#   - _parse_params: Parse required CLI parameter in the form param=value.
#       Parameters:
#           $1 - param_name: Name of the required parameter to look for.
#           $@ - All command-line arguments.
#   - _parse_optional_params: Parse optional CLI parameter in the form param=value.
#       Parameters:
#           $1 - param_name: Name of the optional parameter to look for.
#           $@ - All command-line arguments.
# ==================================================

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