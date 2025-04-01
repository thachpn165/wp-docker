# Check if alias is already set in ~/.bashrc or ~/.zshrc
check_and_add_alias() {
  local shell_config
  local alias_line="alias wpdocker=\"bash \$CLI_DIR/wp-docker-lemp/bin/wp-docker\""
  
  # Check if using Zsh or Bash
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Check if the alias is already present
  if ! grep -q "$alias_line" "$shell_config"; then
    echo "✅ Adding alias for wpdocker to $shell_config..."
    echo "$alias_line" >> "$shell_config"
  else
    echo "⚠️ Alias 'wpdocker' already exists in $shell_config"
  fi

  # Reload the shell configuration file to apply changes
  if [[ "$SHELL" == *"zsh"* ]]; then
    source "$HOME/.zshrc"
  else
    source "$HOME/.bashrc"
  fi
}

# Call the function to check and add alias

