#!/usr/bin/env bash
set -e

REPO_URL="https://raw.githubusercontent.com/r4dn3t/dotnetswitch/main"
BIN_DIR="/usr/local/bin"
SCRIPT_NAME="dotnetswitch"
COMPLETION_FILE="dotnet-switch-completion"
USER_HOME=$(eval echo ~$SUDO_USER)

echo "Downloading dotnetswitch..."
curl -sSL "$REPO_URL/dotnet-switch.sh" -o /tmp/$SCRIPT_NAME

echo "Installing to $BIN_DIR (may require password)..."
chmod +x /tmp/$SCRIPT_NAME
sudo mv /tmp/$SCRIPT_NAME $BIN_DIR/$SCRIPT_NAME

echo "Setting up auto-completion..."
curl -sSL "$REPO_URL/$COMPLETION_FILE" -o "$USER_HOME/.$COMPLETION_FILE"

# Inject into Zsh
if [ -f "$USER_HOME/.zshrc" ]; then
  if ! grep -q "$COMPLETION_FILE" "$USER_HOME/.zshrc"; then
    echo -e "\n# dotnetswitch autocompletion\nautoload -Uz bashcompinit && bashcompinit\nsource ~/.$COMPLETION_FILE" >> "$USER_HOME/.zshrc"
    echo "Added completion to ~/.zshrc"
  fi
fi

# Inject into Bash
if [ -f "$USER_HOME/.bash_profile" ]; then
  if ! grep -q "$COMPLETION_FILE" "$USER_HOME/.bash_profile"; then
    echo -e "\n# dotnetswitch autocompletion\nsource ~/.$COMPLETION_FILE" >> "$USER_HOME/.bash_profile"
    echo "Added completion to ~/.bash_profile"
  fi
fi

echo "Installation complete! Restart your terminal or run 'source ~/.zshrc' to use 'dotnetswitch'."