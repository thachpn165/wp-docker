check_and_add_alias() {
  local shell_config alias_line cli_dir_abs

  # Get the absolute path of the CLI wrapper
  cli_dir_abs="$(realpath "$BASE_DIR/shared/scripts/cli/bashly")"
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  # Determine shell config file
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Add alias only if it doesn't already exist
  if ! grep -Fxq "$alias_line" "$shell_config"; then
    echo "${CHECKMARK} Adding alias for wpdocker to $shell_config..."
    echo "$alias_line" >> "$shell_config"

    # Reload the shell only when alias was added
    print_msg tip "$SUCCESS_RELOAD_AFTER_ADD_ALIAS"
    if [[ "$SHELL" == *"zsh"* ]]; then
      exec zsh
    elif [[ "$SHELL" == *"bash"* ]]; then
      exec bash
    else
      echo "${CROSSMARK} Unsupported shell: $SHELL. Please reload manually."
    fi
  else
    echo "${WARNING} Alias 'wpdocker' already exists in $shell_config"
  fi
}