# =============================================
# 🧩 core_get_installed_version – Get installed WP Docker version
# =============================================
# Description:
#   Retrieves the currently installed version of WP Docker
#   from the `.core.installed_version` field in .config.json.
#
# Returns:
#   - Echoes the installed version string
# =============================================
core_get_installed_version() {
  json_get_value '.core.installed_version'
}

# =============================================
# 📝 core_set_installed_version – Save installed version to config
# =============================================
# Description:
#   Stores the given version string into `.core.installed_version`
#   in the global configuration file (.config.json).
#
# Parameters:
#   $1 - version (required) – Version string to be saved
#
# Globals:
#   .config.json must be accessible and writable
# =============================================
core_set_installed_version() {
  local version="$1"
  json_set_value '.core.installed_version' "$version"
}

# =============================================
# 📦 core_channel_get – Get current update channel
# =============================================
# Description:
#   Retrieves the update channel (official, nightly, dev) from .config.json.
#
# Returns:
#   - Echoes the current update channel
# =============================================
core_channel_get() {
  json_get_value '.core.channel'
}

# =============================================
# 🛠 core_set_channel – Set update channel in config
# =============================================
# Description:
#   Validates and sets the update channel (official, nightly, dev)
#   to `.core.channel` in the .config.json file.
#
# Parameters:
#   $1 - channel (required) – Must be one of: official, nightly, dev
#
# Globals:
#   ERROR_CORE_CHANNEL_INVALID – i18n message for invalid channel
#
# Returns:
#   - Updates config or returns error if invalid
# =============================================
core_set_channel() {
  local channel="$1"
  if [[ "$channel" != "official" && "$channel" != "nightly" && "$channel" != "dev" ]]; then
    print_msg error "Invalid channel: $channel"
    print_msg error "$ERROR_CORE_CHANNEL_INVALID"
    return 1
  fi
  json_set_value '.core.channel' "$channel"
}

# =============================================
# 🧪 core_is_dev_mode – Check if current channel is 'dev'
# =============================================
# Description:
#   Determines if the current channel in .config.json is set to "dev".
#
# Returns:
#   - 0 (true) if dev mode is active
#   - 1 (false) otherwise
# =============================================
core_is_dev_mode() {
  local channel
  channel="$(core_channel_get)"
  [[ "$channel" == "dev" ]]
}