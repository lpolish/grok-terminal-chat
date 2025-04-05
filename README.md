# Grok Terminal Chat

A command-line interface for interacting with Grok AI in your terminal. This tool allows you to chat with Grok and execute system commands through natural language.

## Features

- Interactive chat interface with Grok AI
- Command execution through natural language
- Conversation context maintenance
- Secure API key storage
- Easy installation and uninstallation
- Command history preservation

## Prerequisites

- Python 3
- pip3
- A Grok API key from x.ai
- curl (for direct installation)

## Installation

### Method 1: Direct Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lpolish/grok-terminal-chat/refs/heads/main/install.sh | bash
```

After installation:
```bash
grok --setup  # Configure your API key
```

### Method 2: Manual Installation

1. Clone this repository:
   ```bash
   git clone [repository-url]
   cd grokbash
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
- Install required Python packages (openai)
- Create necessary configuration directories
- Install the `grok` command in `~/.local/bin`

Make sure `~/.local/bin` is in your PATH. If it's not, add this to your `~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

### Basic Commands

```bash
grok              # Start the chat interface
grok --help       # Show help message
grok --setup      # Configure API key
grok --rotate-key # Change API key
grok --uninstall  # Remove the installation
```

### In Chat Commands

- Type `exit` to quit
- Type `clear` to reset conversation context
- Press `Ctrl+C` to exit at any time

### Example Usage

```bash
$ grok
Welcome to Grok Terminal Chat
Type 'exit' to quit, 'clear' to reset context
Press Ctrl+C to exit at any time

You: list the files in the current directory
Grok: I'll help you list the files in the current directory.
EXECUTE: ls -l

Command output:
[files will be listed here]
```

## Configuration

- API Key: Stored in `~/.grok_chat/api_key`
- Conversation Context: Stored in `~/.grok_conversation_context`
- Configuration Directory: `~/.grok_chat/`

## Security

- API key is stored with 600 permissions (user read/write only)
- Configuration directory has 700 permissions (user access only)
- All commands are shown before execution
- Sensitive commands require explicit confirmation

## Uninstallation

To remove Grok Terminal Chat completely:

```bash
grok --uninstall
```

This will:
- Remove the `grok` command
- Delete all configuration files
- Remove the conversation history

## Troubleshooting

1. If `grok` command is not found:
   - Ensure `~/.local/bin` is in your PATH
   - Try running `source ~/.bashrc` or restart your terminal

2. If you get "API key not configured":
   - Run `grok --setup` to configure your API key

3. If Python packages are not found:
   - Run `pip3 install --user openai` manually

## Contributing

Feel free to submit issues and enhancement requests!
