# Check if alias is already set in ~/.bashrc or ~/.zshrc
check_and_add_alias() {
  local shell_config
  local alias_line
  # Get the absolute path of the bin directory
  local cli_dir_abs
  cli_dir_abs=$(realpath "$PROJECT_DIR/shared/bin")
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  # Check if using Zsh or Bash
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Check if the alias is already present
  if ! grep -q "$alias_line" "$shell_config"; then
    echo "${CHECKMARK} Adding alias for wpdocker to $shell_config..."
    echo "$alias_line" >> "$shell_config"
  else
    echo "${WARNING} Alias 'wpdocker' already exists in $shell_config"
  fi
  
  # Reload the shell configuration file to apply changes
  if [[ "$SHELL" == *"zsh"* ]]; then
      # If the current shell is zsh, source .zshrc
      echo "${CHECKMARK} Sourcing .zshrc to reload Zsh configuration..."
      source "$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
      # If the current shell is bash, source .bashrc
      echo "${CHECKMARK} Sourcing .bashrc to reload Bash configuration..."
      source "$HOME/.bashrc"
  else
      echo "${CROSSMARK} Unsupported shell: $SHELL. Please reload your shell configuration manually."
  fi

}