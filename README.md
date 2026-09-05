# dotnetswitch

A macOS bash utility to dynamically download, install, and switch .NET SDK versions per project.

As noted in the **C# Programing** reference, historically, C# was Windows-only, but modern .NET is fully cross-platform. Setting up your Mac is straightforward. Installing the .NET SDK provides the `dotnet` CLI, which is the backbone of building, running, and managing your apps. However, navigating multiple SDKs can occasionally cause runtime or path resolution errors, such as missing `osx-x64` paths on a Mac. **dotnetswitch** automates your environment setup by managing architecture detection, remote fetching, and local version pinning.

## Features

* **Architecture Detection:** Automatically requests the correct Apple Silicon (`arm64`) or Intel (`x64`) macOS binaries to prevent compatibility crashes and missing path errors.


* **Seamless Switching:** Generates a `global.json` file to pin a specific project directory to your desired SDK version.
* **Channel Fetching:** Queries Microsoft's official release metadata to list all available .NET channels.
* **Auto-Downloading:** If a requested SDK is missing, it downloads and installs it directly to `/usr/local/share/dotnet` in the background.

## Installation

**Option 1: One-Line Auto-Installer (Recommended)**
Run the following command to automatically download the script, move it to your global binaries, and configure tab-autocompletion in your shell profile:

```bash
curl -sSL https://raw.githubusercontent.com/r4dn3t/dotnetswitch/main/install.sh | bash

```

**Option 2: Manual Global Installation**
To ensure the command is accessible from any folder on your machine, a developer should add this file to its `/usr/local/bin` directory to use it globally.

1. Make the core script executable:
```bash
chmod +x dotnet-switch.sh

```


2. Move it to your local binaries:
```bash
sudo mv dotnet-switch.sh /usr/local/bin/dotnetswitch

```


3. For tab-completion, download the `dotnet-switch-completion` file from the repository, save it to `~/.dotnet-switch-completion`, and append `source ~/.dotnet-switch-completion` to your `~/.zshrc` or `~/.bash_profile`.

## Usage

Run `dotnetswitch` without arguments to launch the interactive prompt.

* **`-l`, `--list**`: List currently installed .NET SDKs on your local machine.
* **`-c`, `--channels**`: Fetch and list available .NET channels directly from Microsoft's release API.
* **`-i`, `--install [VERSION]**`: Explicitly download and install a specific SDK version or channel (e.g., `dotnetswitch -i 6.0`).
* **`[VERSION]`**: Pass a specific version to bypass the prompt and instantly pin your current directory via `global.json` (e.g., `dotnetswitch 6.0.428`).

## License

This project is licensed under the **MIT License**. You are free to use, modify, and distribute this software as is, without warranty.