Grok Terminal Chat
A command-line interface for interacting with Grok AI in your terminal. Chat with Grok and execute system commands using natural language.
Features

Interactive chat with Grok AI
Execute system commands via natural language
Persistent conversation context
Secure API key storage
Easy installation and uninstallation
Command history preservation

Supported Operating Systems

Debian-based (Ubuntu, Debian)
Red Hat-based (Fedora, CentOS, RHEL, Amazon Linux 2/2023)
Arch Linux
openSUSE
Alpine Linux

Prerequisites

Python 3.6 or higher
pip3
A Grok API key (obtain from xAI API)
curl (for direct installation)
sudo privileges for installation

Installation
Method 1: Direct Installation (Recommended)
curl -fsSL https://raw.githubusercontent.com/lpolish/grok-terminal-chat/main/install.sh | sudo bash

Then configure your API key:
sudo grok --setup

Method 2: Manual Installation

Clone the repository:
git clone https://github.com/lpolish/grok-terminal-chat.git
cd grok-terminal-chat


Run the installer with sudo:
sudo ./install.sh


Configure your API key:
sudo grok --setup



The installer will:

Install required system packages (Python, pip, virtualenv)
Set up a Python virtual environment in /opt/grok_venv
Install the grok command in /usr/local/bin
Create configuration directories (/etc/grok_chat, /var/lib/grok)

Usage
Basic Commands
grok              # Start the chat interface
grok --help       # Show help message
grok --setup      # Configure API key
grok --rotate-key # Update API key
grok --uninstall  # Remove Grok

In-Chat Commands

exit: Quit the chat
clear: Reset conversation context
Ctrl+C: Exit immediately

Example
$ grok
Grok Terminal Chat
Type 'exit' to quit, 'clear' to reset context

You: List files in the current directory
Grok: EXECUTE: ls -l
Command output:
total 8
-rw-r--r-- 1 user user 1234 Apr 18 2025 file1.txt
-rw-r--r-- 1 user user 5678 Apr 18 2025 file2.txt

Configuration

API Key: Stored in /etc/grok_chat/api_key
Conversation Context: Stored in /var/lib/grok/conversation_context
Configuration Directory: /etc/grok_chat

Security

API key permissions: 600 (user read/write only)
Configuration directory permissions: 700 (user access only)
Commands are displayed before execution
Sensitive commands require confirmation

Uninstallation
To remove Grok Terminal Chat:
sudo grok --uninstall

This will:

Remove the grok command
Delete configuration files and directories
Remove the virtual environment
Erase conversation history

Troubleshooting

"grok: command not found":

Ensure /usr/local/bin is in your PATH: export PATH=/usr/local/bin:$PATH
Verify installation with ls /usr/local/bin/grok


"API key not configured":

Run sudo grok --setup to set your API key


Package installation fails:

Ensure internet connectivity
For Alpine Linux, verify main and community repositories are enabled in /etc/apk/repositories
Manually install Python: # Alpine: sudo apk add python3 py3-pip
# Amazon Linux 2: sudo yum install python3 python3-pip




Python package errors:

Manually install the openai package: sudo /opt/grok_venv/bin/pip install openai



Contributing
Submit issues or pull requests at github.com/lpolish/grok-terminal-chat.
License
MIT License
