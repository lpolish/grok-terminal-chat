# Grok Terminal Chat

A bash script that provides a terminal-based interface to interact with Grok,
maintaining conversation context and supporting command execution with safety confirmations.

## Features
- Persistent conversation context stored in ~/.grok_conversation_context
- Secure API key storage using SHA-256 hashing
- Color-coded terminal output
- Command execution support with confirmation for potentially destructive operations
- Installs to ~/.local/bin for user-specific access
- Self-contained installer with setup and uninstall options

## Installation

### Method 1: Direct Download and Install

1. Download install.sh
2. Make it executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the installer:
   ```bash
   ./install.sh
   ```
4. Setup API key:
   ```bash
   ./install.sh --setup
   ```

### Method 2: Install via curl (Recommended)

```bash
curl -fsSL https://github.com/lpolish/grok-terminal-chat/raw/main/install.sh | bash
```
Then setup API key:

```bash
install.sh --setup
```
Replace username/repo with your actual GitHub username and repository name.

### Post-Installation
- If the command grok-chat isn't immediately available:
  - Run source ~/.bashrc or
  - Open a new terminal window
- The script adds ~/.local/bin to your PATH in ~/.bashrc if not already present

## Usage
- Start the chat: grok-chat
- Enter your API key when prompted (input is hidden)
- Type messages to interact with Grok
- Special commands:
  - exit: Quit the chat
  - clear: Reset conversation context
  - execute:command or run:command: Execute shell commands
    - Potentially destructive commands (rm, mv, cp) require confirmation

## Uninstallation
Run the installer with the uninstall option:

```bash
install.sh --uninstall
```
- Confirms before removing the script
- Offers to remove configuration and conversation context files
- Note: Does not remove the PATH entry from ~/.bashrc; edit manually if desired

## Notes
- This is a simulation; real Grok integration requires xAI API access
- Replace the send_to_grok function with actual API calls when integrating with xAI
- API key is not stored in plaintext; only its hash is kept for verification
- Customize the GitHub URL in the curl command based on your repository location
