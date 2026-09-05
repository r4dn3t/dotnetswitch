#!/usr/bin/env bash
set -e

readonly INSTALL_DIR="/usr/local/share/dotnet"

show_help() {
  cat << EOF
Usage: dotnet-switch.sh [OPTIONS] [VERSION]

Automatically change, download, and activate a specific .NET SDK version via global.json.

Options:
  -h, --help      Display this help text and exit
  -l, --list      List currently installed .NET SDKs
  -c, --channels  Fetch and list available .NET channels from Microsoft
  -i, --install   Explicitly download and install a specific SDK version or channel

Arguments:
  VERSION         The exact .NET version or channel (e.g., 6.0, 8.0, 6.0.428)
EOF
}

# Display help if no arguments are passed
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

# Route flags using a modern case statement
case "$1" in
  -h|--help)
    show_help
    exit 0
    ;;
  -l|--list)
    echo "Currently installed .NET SDKs:"
    dotnet --list-sdks | awk '{print " - " $1}'
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
      echo "Error: Please provide a version to install (e.g., ./dotnet-switch.sh -i 6.0)"
      exit 1
    fi
    INSTALL_VERSION="$2"
    echo "Initiating explicit download for SDK '$INSTALL_VERSION'..."
    INSTALL_FLAG=$([[ "$INSTALL_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] && echo "--channel $INSTALL_VERSION" || echo "--version $INSTALL_VERSION")
    
    curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    chmod +x /tmp/dotnet-install.sh
    sudo /tmp/dotnet-install.sh $INSTALL_FLAG --install-dir "$INSTALL_DIR"
    rm -f /tmp/dotnet-install.sh
    
    echo "Installation complete. Run without flags to activate it."
    exit 0
    ;;
  -*)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
esac

# Detect Mac Architecture
ARCH_FLAG=""
if [[ "$(uname -m)" == "arm64" ]]; then
  ARCH_FLAG="--architecture arm64"
fi

case "$1" in
  # ... (keep other cases) ...
  -i|--install)
    if [[ -z "$2" ]]; then
      echo "Error: Please provide a version to install (e.g., ./dotnet-switch.sh -i 6.0)"
      exit 1
    fi
    INSTALL_VERSION="$2"
    echo "Initiating explicit download for SDK '$INSTALL_VERSION'..."
    INSTALL_FLAG=$([[ "$INSTALL_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] && echo "--channel $INSTALL_VERSION" || echo "--version $INSTALL_VERSION")
    
    curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    chmod +x /tmp/dotnet-install.sh
    sudo /tmp/dotnet-install.sh $INSTALL_FLAG $ARCH_FLAG --install-dir "$INSTALL_DIR"
    rm -f /tmp/dotnet-install.sh
    
    echo "Installation complete. Run without flags to activate it."
    exit 0
    ;;
  -*)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
esac

INPUT_VERSION="$1"
MATCHING_SDK=$(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | grep "^${INPUT_VERSION}" | tail -n 1 || true)

if [[ -z "$MATCHING_SDK" ]]; then
  echo "SDK matching '$INPUT_VERSION' not found. Initiating auto-download..."
  INSTALL_FLAG=$([[ "$INPUT_VERSION" =~ ^[0-9]+\.[0-9]+$ ]] && echo "--channel $INPUT_VERSION" || echo "--version $INPUT_VERSION")

  curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  chmod +x /tmp/dotnet-install.sh
  sudo /tmp/dotnet-install.sh $INSTALL_FLAG $ARCH_FLAG --install-dir "$INSTALL_DIR"
  rm -f /tmp/dotnet-install.sh

  MATCHING_SDK=$(dotnet --list-sdks | awk '{print $1}' | grep "^${INPUT_VERSION}" | tail -n 1 || true)
  [[ -z "$MATCHING_SDK" ]] && { echo "Error: Installation failed."; exit 1; }
fi

# ... (keep the pinning logic at the end) ...