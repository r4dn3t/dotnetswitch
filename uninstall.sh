#!/usr/bin/env bash
set -e

BIN_DIR="/usr/local/bin"
SCRIPT_NAME="dotnetswitch"
COMPLETION_FILE=".dotnet-switch-completion"
USER_HOME=$(eval echo ~$SUDO_USER)

echo "Uninstalling dotnetswitch..."

# 1. Remove the global executable
if [ -f "$BIN_DIR/$SCRIPT_NAME" ]; then
  sudo rm -f "$BIN_DIR/$SCRIPT_NAME"
  echo " - Removed $BIN_DIR/$SCRIPT_NAME"
fi

# 2. Remove the autocomplete file
if [ -f "$USER_HOME/$COMPLETION_FILE" ]; then
  rm -f "$USER_HOME/$COMPLETION_FILE"
  echo " - Removed $USER_HOME/$COMPLETION_FILE"
fi

# 3. Clean up shell profiles (macOS requires the empty string '' for sed inplace edits)
if [ -f "$USER_HOME/.zshrc" ]; then
  sed -i '' '/# dotnetswitch autocompletion/d' "$USER_HOME/.zshrc"
  sed -i '' '/autoload -Uz bashcompinit && bashcompinit/d' "$USER_HOME/.zshrc"
  sed -i '' '/source ~\/.dotnet-switch-completion/d' "$USER_HOME/.zshrc"
  echo " - Cleaned ~/.zshrc"
fi

if [ -f "$USER_HOME/.bash_profile" ]; then
  sed -i '' '/# dotnetswitch autocompletion/d' "$USER_HOME/.bash_profile"
  sed -i '' '/source ~\/.dotnet-switch-completion/d' "$USER_HOME/.bash_profile"
  echo " - Cleaned ~/.bash_profile"
fi

echo "Uninstallation complete! Please restart your terminal."