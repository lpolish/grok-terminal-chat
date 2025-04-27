# Grok Terminal Chat

A command-line interface for interacting with Grok AI in your terminal. Chat with Grok and execute system commands using natural language.

## Features

- Interactive chat with Grok AI
- Execute system commands via natural language
- Persistent conversation context
- Secure API key storage
- Easy installation and uninstallation
- Command history preservation
- No root access required

## Supported Operating Systems

- Debian-based (Ubuntu, Debian)
- Red Hat-based (Fedora, CentOS, RHEL, Amazon Linux 2/2023)
- Arch Linux
- openSUSE
- Alpine Linux

## Prerequisites

- Python 3.6 or higher
- pip3
- A Grok API key (obtain from [xAI API](https://x.ai/api))
- curl (for direct installation)

## Installation

### Method 1: Direct Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lpolish/grok-terminal-chat/main/install.sh | bash
```

Then configure your API key:
```bash
grok --setup
```

### Method 2: Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/lpolish/grok-terminal-chat.git
   cd grok-terminal-chat
   ```

2. Run the installer:
   ```bash
   ./install.sh
   ```

3. Configure your API key:
   ```bash
   grok --setup
   ```

The installer will:
- Set up Python if not already installed (may require sudo if Python is not present)
- Create a Python virtual environment in `~/.local/share/grok/venv`
- Install the `grok` command in `~/.local/bin`
- Create configuration directories in `~/.config/grok_chat` and `~/.local/share/grok`

## Usage

### Basic Commands

```bash
grok              # Start the chat interface
grok --help       # Show help message
grok --setup      # Configure API key
grok --rotate-key # Update API key
grok --uninstall  # Remove Grok
```

### In-Chat Commands

- `exit`: Quit the chat
- `clear`: Reset conversation context
- `Ctrl+C`: Exit immediately

### Example

```bash
$ grok
Grok Terminal Chat
Type 'exit' to quit, 'clear' to reset context

You: List files in the current directory
Grok: EXECUTE: ls -l
Command output:
total 8
-rw-r--r-- 1 user user 1234 Apr 18 2025 file1.txt
-rw-r--r-- 1 user user 5678 Apr 18 2025 file2.txt
```

## Configuration

- **API Key**: Stored in `~/.config/grok_chat/api_key`
- **Conversation Context**: Stored in `~/.local/share/grok/conversation_context`
- **Configuration Directory**: `~/.config/grok_chat`

## Security

- API key permissions: 600 (user read/write only)
- Configuration directory permissions: 700 (user access only)
- Commands are displayed before execution
- Sensitive commands require confirmation
- All files are stored in user-specific directories

## Uninstallation

To remove Grok Terminal Chat:

```bash
grok --uninstall
```

This will:
- Remove the `grok` command
- Delete configuration files and directories
- Remove the virtual environment
- Erase conversation history

## Troubleshooting

- **"grok: command not found"**:
  - Ensure `~/.local/bin` is in your PATH
  - Log out and log back in, or run: `export PATH="$HOME/.local/bin:$PATH"`
  - Verify installation with `ls ~/.local/bin/grok`

- **"API key not configured"**:
  - Run `grok --setup` to set your API key

- **Python not found**:
  - Install Python through your system's package manager
  - For most systems: `sudo apt install python3` (Ubuntu/Debian)
  - For Alpine: `sudo apk add python3`
  - For RHEL/CentOS: `sudo yum install python3`

- **Python package errors**:
  - Manually install the `openai` package: `~/.local/share/grok/venv/bin/pip install openai`

## Contributing

Submit issues or pull requests at [github.com/lpolish/grok-terminal-chat](https://github.com/lpolish/grok-terminal-chat).

## License

MIT License
