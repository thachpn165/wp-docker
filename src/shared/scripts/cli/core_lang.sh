#!/bin/bash
# ==================================================
# File: core_lang.sh
# Description: CLI wrapper to manage language settings, including changing the current language, 
#              displaying the current language, and listing supported languages.
# Functions:
#   - core_lang_cli_change: Change the current language.
#       Parameters:
#           --lang=<language_code>: The language code to set (e.g., "en").
#       Returns: 0 if successful, 1 otherwise.
#   - core_lang_cli_get: Display the current language.
#       Parameters: None.
#       Returns: None.
#   - core_lang_cli_list: List all supported languages.
#       Parameters: None.
#       Returns: None.
# ==================================================

# Auto-detect BASE_DIR and load config
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load core logic functions
safe_source "$FUNCTIONS_DIR/core_loader.sh"

core_lang_cli_change() {
    local lang_code
    lang_code=$(_parse_params "--lang" "$@")

    _is_missing_param "$lang_code" "--lang" || return 1

    core_lang_change_logic "$lang_code"
}

core_lang_cli_get() {
    local current_lang
    current_lang=$(core_lang_get_logic)
    print_msg info "$INFO_CURRENT_LANG: $current_lang"
}

core_lang_cli_list() {
    local available_langs
    available_langs=$(core_lang_list_logic)
    print_msg info "$INFO_AVAILABLE_LANGS\n\n$available_langs"
    echo ""
    print_msg tip "$TIPS_CHANGE_LANG"
}