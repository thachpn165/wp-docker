#!/bin/bash

# =====================================
# 🌐 core_lang_cli.sh – CLI wrapper to manage language settings
# =====================================

# === Auto-detect BASE_DIR and load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load core logic functions ===
safe_source "$FUNCTIONS_DIR/core_loader.sh"

# =====================================
# 🔄 core_lang_cli_change: Change current language
# Usage: core_lang_cli_change --lang=en
# =====================================
core_lang_cli_change() {
    local lang_code
    lang_code=$(_parse_params "--lang" "$@")

    if [[ -z "$lang_code" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --lang"
        print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --lang=en"
        exit 1
    fi

    core_lang_change_logic "$lang_code"
}

# =====================================
# 📖 core_lang_cli_get: Show current language
# Usage: core_lang_cli_get
# =====================================
core_lang_cli_get() {
    local current_lang
    current_lang=$(core_lang_get_logic)
    print_msg info "$INFO_CURRENT_LANG: $current_lang"
}

# =====================================
# 📜 core_lang_cli_list: List supported languages
# Usage: core_lang_cli_list
# =====================================
core_lang_cli_list() {
    local available_langs
    available_langs=$(core_lang_list_logic)
    print_msg info "$INFO_AVAILABLE_LANGS\n\n$available_langs"
    echo ""
    print_msg tip "$TIPS_CHANGE_LANG"
}
