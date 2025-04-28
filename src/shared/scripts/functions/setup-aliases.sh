check_and_add_alias() {
  local shell_config cli_dir_abs alias_line needs_update=false

  cli_dir_abs=$(realpath "$CLI_DIR/bashly")
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Check if alias wpdocker exists
  if grep -q "alias wpdocker=" "$shell_config"; then
    # Check if the specific path exists in the alias
    if ! grep -q "alias wpdocker=.*shared/scripts/cli/bashly/wpdocker" "$shell_config"; then
      debug_log "🧹 Removing existing alias from $shell_config (wrong path)..."
      # Remove the existing alias
      sedi '/alias wpdocker=/d' "$shell_config"

      needs_update=true
    else
      debug_log "✓ Alias wpdocker already exists with correct path."
      return 0
    fi
  else
    needs_update=true
  fi

  if [[ "$needs_update" == true ]]; then
    echo "$alias_line" >>"$shell_config"

    echo "$TIP_RELOAD_SHELL"
    echo "   source $shell_config"

    # Create alias in the current session so the user can use it immediately
    eval "$alias_line"
  fi
}
