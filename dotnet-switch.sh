#!/usr/bin/env bash
set -e

readonly INSTALL_DIR="/usr/local/share/dotnet"
readonly GLOBAL_JSON_HOME="$HOME/global.json"

# Colors for terminal output
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  CYAN="\033[0;36m"
  RESET="\033[0m"
else
  BOLD=""
  GREEN=""
  YELLOW=""
  CYAN=""
  RESET=""
fi

# Detect Mac Architecture
ARCH_FLAG=""
if [[ "$(uname -m)" == "arm64" ]]; then
  ARCH_FLAG="--architecture arm64"
fi

show_help() {
  cat << EOF
Usage: dotnetswitch [OPTIONS] [VERSION]

Manage, switch, and install .NET SDK versions globally or per directory.

Options:
  -s, --status         Display global and directory-level .NET SDK status
  -g, --global         Set or target the global .NET SDK version (~/global.json)
  -d, --directory      Set or target the directory-level (local) .NET SDK version (./global.json)
  -u, --unset          Remove global.json configuration (global or directory)
  -l, --list           List currently installed .NET SDKs
  -c, --channels       Fetch and list available .NET channels from Microsoft
  -i, --install        Explicitly download and install a specific SDK version or channel
  -h, --help           Display this help text and exit

Arguments:
  VERSION              The exact .NET version or channel (e.g., 6.0, 8.0, 6.0.428)
EOF
}

# Extracts the version string from a global.json file
get_json_sdk_version() {
  local json_file="$1"
  if [[ -f "$json_file" ]]; then
    if command -v python3 &>/dev/null; then
      python3 -c "import json; print(json.load(open('$json_file')).get('sdk', {}).get('version', ''))" 2>/dev/null || true
    else
      grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" 2>/dev/null | head -n 1 | cut -d'"' -f4 || true
    fi
  fi
}

# Writes or updates a global.json file with specified SDK version
set_json_sdk_version() {
  local json_file="$1"
  local version="$2"
  cat << EOF > "$json_file"
{
  "sdk": {
    "version": "$version"
  }
}
EOF
}

# Get global .NET SDK version status
get_global_status() {
  local ver=""
  if [[ -f "$GLOBAL_JSON_HOME" ]]; then
    ver=$(get_json_sdk_version "$GLOBAL_JSON_HOME")
    if [[ -n "$ver" ]]; then
      echo "$ver (~/global.json)"
      return
    fi
  fi
  if command -v dotnet &>/dev/null; then
    ver=$(dotnet --version 2>/dev/null || true)
    if [[ -n "$ver" ]]; then
      echo "$ver (system default)"
      return
    fi
  fi
  echo "Not installed / Not available"
}

# Get directory level .NET SDK version status
get_directory_status() {
  local cwd="$PWD"
  local ver=""

  if [[ -f "./global.json" && "$cwd" != "$HOME" ]]; then
    ver=$(get_json_sdk_version "./global.json")
    if [[ -n "$ver" ]]; then
      echo "$ver (./global.json)"
      return
    fi
  fi

  local dir="$cwd"
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    dir=$(dirname "$dir")
    if [[ -f "$dir/global.json" && "$dir" != "$HOME" ]]; then
      ver=$(get_json_sdk_version "$dir/global.json")
      if [[ -n "$ver" ]]; then
        echo "$ver (inherited from $dir/global.json)"
        return
      fi
    fi
  done

  echo "Not set (using global SDK)"
}

show_status() {
  echo -e "${BOLD}.NET SDK Status:${RESET}"
  echo -e "  ${CYAN}Global SDK:${RESET}    $(get_global_status)"
  echo -e "  ${CYAN}Directory SDK:${RESET} $(get_directory_status)"
}

# Ensure SDK is installed, download if missing
ensure_sdk_installed() {
  local input_version="$1"
  local matching_sdk

  matching_sdk=$(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | grep "^${input_version}" | tail -n 1 || true)

  if [[ -z "$matching_sdk" ]]; then
    echo "SDK matching '$input_version' not found. Initiating auto-download..." >&2
    local install_flag
    install_flag=$([[ "$input_version" =~ ^[0-9]+\.[0-9]+$ ]] && echo "--channel $input_version" || echo "--version $input_version")

    curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    chmod +x /tmp/dotnet-install.sh
    sudo /tmp/dotnet-install.sh $install_flag $ARCH_FLAG --install-dir "$INSTALL_DIR" >&2
    rm -f /tmp/dotnet-install.sh

    matching_sdk=$(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | grep "^${input_version}" | tail -n 1 || true)
    if [[ -z "$matching_sdk" ]]; then
      echo -e "${YELLOW}Error: Installation failed for '$input_version'.${RESET}" >&2
      exit 1
    fi
  fi

  echo "$matching_sdk"
}

# Set SDK version for specified target file
set_sdk_version() {
  local target_scope="$1" # "global" or "directory"
  local input_version="$2"
  local target_file

  if [[ "$target_scope" == "global" ]]; then
    target_file="$GLOBAL_JSON_HOME"
  else
    target_file="./global.json"
  fi

  if [[ -z "$input_version" ]]; then
    echo -e "${BOLD}Currently installed .NET SDKs:${RESET}"
    dotnet --list-sdks 2>/dev/null | awk '{print " - " $1}'
    echo ""
    read -rp "Enter .NET SDK version to set ($target_scope): " input_version
    if [[ -z "$input_version" ]]; then
      echo "No version specified. Aborting."
      exit 1
    fi
  fi

  local resolved_sdk
  resolved_sdk=$(ensure_sdk_installed "$input_version")

  set_json_sdk_version "$target_file" "$resolved_sdk"
  echo -e "${GREEN}Successfully set $target_scope .NET SDK version to ${BOLD}${resolved_sdk}${RESET}${GREEN} ($target_file)${RESET}"
}

# Unset SDK version (remove global.json)
unset_sdk_version() {
  local target_scope="$1" # "global" or "directory"

  if [[ "$target_scope" == "global" ]]; then
    if [[ -f "$GLOBAL_JSON_HOME" ]]; then
      rm -f "$GLOBAL_JSON_HOME"
      echo -e "${GREEN}Removed global SDK pin ($GLOBAL_JSON_HOME).${RESET}"
    else
      echo "No global SDK pin ($GLOBAL_JSON_HOME) found."
    fi
  elif [[ "$target_scope" == "directory" ]]; then
    if [[ -f "./global.json" ]]; then
      rm -f "./global.json"
      echo -e "${GREEN}Removed directory SDK pin (./global.json).${RESET}"
    else
      echo "No directory SDK pin (./global.json) found in current directory."
    fi
  else
    if [[ -t 0 ]]; then
      echo -e "${BOLD}Select scope to unset:${RESET}"
      echo "  1) Directory level (./global.json)"
      echo "  2) Global level (~/global.json)"
      read -rp "Choice [1/2]: " choice
      case "$choice" in
        1) unset_sdk_version "directory" ;;
        2) unset_sdk_version "global" ;;
        *) echo "Invalid choice. Aborting." ;;
      esac
    else
      echo "Please specify scope to unset: --unset global or --unset directory"
      exit 1
    fi
  fi
}

# Interactive Menu
interactive_menu() {
  show_status
  echo ""
  echo -e "${BOLD}Select an action:${RESET}"
  echo "  1) Set Directory .NET SDK version (./global.json)"
  echo "  2) Set Global .NET SDK version (~/global.json)"
  echo "  3) Unset Directory .NET SDK version"
  echo "  4) Unset Global .NET SDK version"
  echo "  5) Install a new .NET SDK version"
  echo "  6) List installed .NET SDKs"
  echo "  7) List available .NET channels"
  echo "  8) Exit"
  echo ""
  read -rp "Choice [1-8]: " choice

  case "$choice" in
    1) set_sdk_version "directory" "" ;;
    2) set_sdk_version "global" "" ;;
    3) unset_sdk_version "directory" ;;
    4) unset_sdk_version "global" ;;
    5)
      read -rp "Enter .NET version or channel to install (e.g. 8.0): " install_ver
      if [[ -n "$install_ver" ]]; then
        ensure_sdk_installed "$install_ver" >/dev/null
        echo -e "${GREEN}SDK '$install_ver' installed successfully.${RESET}"
      fi
      ;;
    6)
      echo -e "${BOLD}Currently installed .NET SDKs:${RESET}"
      dotnet --list-sdks 2>/dev/null | awk '{print " - " $1}'
      ;;
    7)
      echo "Fetching available .NET channels from Microsoft..."
      curl -s https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json | \
        grep '"channel-version"' | awk -F'"' '{print " - " $4}'
      ;;
    8) exit 0 ;;
    *) echo "Invalid option." ;;
  esac
}

# Handle main arguments
if [[ $# -eq 0 ]]; then
  if [[ -t 0 ]]; then
    interactive_menu
    exit 0
  else
    show_status
    exit 0
  fi
fi

case "$1" in
  -h|--help)
    show_help
    exit 0
    ;;
  -s|--status|status)
    show_status
    exit 0
    ;;
  -g|--global)
    set_sdk_version "global" "$2"
    exit 0
    ;;
  -d|--directory|--local)
    set_sdk_version "directory" "$2"
    exit 0
    ;;
  -u|--unset)
    unset_sdk_version "$2"
    exit 0
    ;;
  -l|--list)
    echo -e "${BOLD}Currently installed .NET SDKs:${RESET}"
    dotnet --list-sdks 2>/dev/null | awk '{print " - " $1}'
    exit 0
    ;;
  -c|--channels)
    echo "Fetching available .NET channels from Microsoft..."
    curl -s https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json | \
      grep '"channel-version"' | awk -F'"' '{print " - " $4}'
    exit 0
    ;;
  -i|--install)
    if [[ -z "$2" ]]; then
      echo "Error: Please provide a version to install (e.g., dotnetswitch -i 8.0)"
      exit 1
    fi
    ensure_sdk_installed "$2" >/dev/null
    echo -e "${GREEN}Installation complete for '$2'.${RESET}"
    exit 0
    ;;
  -*)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
  *)
    # Version argument supplied without scope flag (e.g., dotnetswitch 8.0.400)
    INPUT_VERSION="$1"
    if [[ -t 0 ]]; then
      echo -e "${BOLD}Set version '$INPUT_VERSION' for:${RESET}"
      echo "  1) Directory scope (./global.json) [Default]"
      echo "  2) Global scope (~/global.json)"
      read -rp "Choice [1/2]: " scope_choice
      if [[ "$scope_choice" == "2" ]]; then
        set_sdk_version "global" "$INPUT_VERSION"
      else
        set_sdk_version "directory" "$INPUT_VERSION"
      fi
    else
      set_sdk_version "directory" "$INPUT_VERSION"
    fi
    exit 0
    ;;
esac