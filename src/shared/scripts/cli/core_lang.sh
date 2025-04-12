#!/bin/bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/core_loader.sh"


# === Change Language ===
# usage: core_lang_cli_change --lang=en
core_lang_cli_change() {
    
    # Parse --lang from argument
    for arg in "$@"; do
        case $arg in
            --lang=*) lang_code="${arg#*=}" ;;
            *)
                print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
                print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --lang=en"
                exit 1
                ;;
        esac
    done

    # Call logic function to change language
    core_lang_change_logic "$lang_code"
}

# == Get Current Language ==
# usage: core_lang_cli_get
core_lang_cli_get() {
    # Call logic function to get current language
    local current_lang
    current_lang=$(core_lang_get_logic)
    print_msg info "$INFO_CURRENT_LANG: $current_lang"
}


# == List Available Languages ==
# usage: core_lang_cli_list
core_lang_cli_list() {
    # Call logic function to list available languages
    local available_langs
    available_langs=$(core_lang_list_logic)
    print_msg info "$INFO_AVAILABLE_LANGS\n\n$available_langs"
    echo ""
    print_msg tip "$TIPS_CHANGE_LANG"
}