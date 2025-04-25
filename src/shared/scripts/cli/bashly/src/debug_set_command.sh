#!/bin/bash

# Check if required variables are set
if [[ -z "${args[action]}" || -z "$WPDOCKER_CONFIG_FILE" ]]; then
    echo "Error: Missing required arguments or configuration file."
    exit 1
fi

# Ensure the configuration file exists
if [[ ! -f "$WPDOCKER_CONFIG_FILE" ]]; then
    echo "Error: Configuration file '$WPDOCKER_CONFIG_FILE' not found."
    exit 1
fi

# Perform action based on ${args[action]}
case "${args[action]}" in
enable)
    if grep -q 'DEBUG_MODE="true"' "$WPDOCKER_CONFIG_FILE"; then
        echo "DEBUG_MODE is already enabled."
    else
        sedi 's/DEBUG_MODE="false"/DEBUG_MODE="true"/' "$WPDOCKER_CONFIG_FILE"
        echo "DEBUG_MODE has been enabled."
    fi
    ;;
disable)
    if grep -q 'DEBUG_MODE="false"' "$WPDOCKER_CONFIG_FILE"; then
        echo "DEBUG_MODE is already disabled."
    else
        sedi 's/DEBUG_MODE="true"/DEBUG_MODE="false"/' "$WPDOCKER_CONFIG_FILE"
        echo "DEBUG_MODE has been disabled."
    fi
    ;;
*)
    echo "Error: Invalid action '${args[action]}'. Use 'enable' or 'disable'."
    exit 1
    ;;
esac
