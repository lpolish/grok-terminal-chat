# Grok Terminal Chat

A command-line interface for interacting with the Grok AI model. This tool provides a simple and secure way to chat with Grok directly from your terminal.

## Features

- Secure API key management
- Persistent conversation context
- Command execution capabilities
- Clean and intuitive interface
- Easy installation and uninstallation

## Prerequisites

- Bash shell
- `curl` command-line tool
- Internet connection
- Grok API key (when available)

## Installation

### Method 1: Direct Download
1. Clone this repository or download the `install.sh` script
2. Make the script executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the installer:
   ```bash
   ./install.sh
   ```

### Method 2: Install via curl (Recommended)
```bash
# Download and execute in one step
curl -fsSL https://raw.githubusercontent.com/lpolish/grok-terminal-chat/main/install.sh | bash

# Or download first, then execute (if you prefer to inspect the script)
curl -fsSL https://raw.githubusercontent.com/lpolish/grok-terminal-chat/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The installer will:
- Create necessary directories
- Install the script to `~/.local/bin`
- Add the directory to your PATH if needed
- Set up secure permissions

## Usage

### Basic Commands

- Start the chat:
  ```bash
  grok
  ```

- Configure API key:
  ```bash
  grok --setup
  ```

- Show help:
  ```bash
  grok --help
  ```

- Uninstall:
  ```bash
  grok --uninstall
  ```

### Chat Commands

- Type your message and press Enter to chat
- Type `exit` to quit
- Type `clear` to reset the conversation context
- Use `execute:` or `run:` prefix to execute commands (with safety checks)

### API Key Management

The API key is stored securely:
- The actual key is stored in `~/.grok_chat/api_key`
- A hash of the key is stored for verification
- Both files have restricted permissions (600)

## Security Features

- API keys are stored with restricted permissions
- Command execution requires confirmation
- Potentially dangerous commands are flagged
- Secure file permissions throughout

## File Locations

- Main script: `~/.local/bin/grok`
- Configuration: `~/.grok_chat/`
- Conversation context: `~/.grok_conversation_context`

## Uninstallation

The uninstaller will:
- Remove the main script
- Optionally remove configuration files
- Optionally remove conversation context
- Provide instructions for PATH cleanup

## Troubleshooting

1. If the command is not found:
   ```bash
   source ~/.bashrc
   ```

2. If API key issues occur:
   ```bash
   grok --setup
   ```

3. For permission issues:
   ```bash
   chmod 600 ~/.grok_chat/api_key
   chmod 600 ~/.grok_chat/api_key_hash
   ```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Note

This is a community project and is not officially affiliated with xAI or Grok. The API endpoint and authentication method may need to be updated once the official Grok API is released.
