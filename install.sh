#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# System-wide installation paths
CONFIG_DIR="/etc/grok_chat"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="grok"
CONTEXT_FILE="/var/lib/grok/conversation_context"
API_KEY_FILE="$CONFIG_DIR/api_key"
REQUIREMENTS_FILE="$CONFIG_DIR/requirements.txt"

# Function to install system dependencies
install_system_deps() {
    echo -e "${BLUE}Installing system dependencies...${NC}"
    
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        yum install -y python3 python3-pip
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf install -y python3 python3-pip
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        pacman -Sy --noconfirm python python-pip
    elif command -v zypper &> /dev/null; then
        # OpenSUSE
        zypper install -y python3 python3-pip
    else
        echo -e "${YELLOW}Could not detect package manager. Attempting to continue...${NC}"
    fi
}

create_python_script() {
    cat > "$CONFIG_DIR/chat.py" << 'EOF'
import os
import sys
import json
import subprocess
import re
from openai import OpenAI

def load_context(context_file):
    try:
        with open(context_file, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []

def execute_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        return result.stdout if result.stdout else result.stderr
    except Exception as e:
        return f"Error executing command: {str(e)}"

def chat(api_key, message, context_file):
    try:
        client = OpenAI(
            api_key=api_key,
            base_url="https://api.x.ai/v1"
        )
        
        messages = load_context(context_file)
        
        system_message = {
            "role": "system",
            "content": """You can help users interact with their system through commands.
            To execute a command, prefix it with 'EXECUTE: ' followed by the command.
            Example: 'EXECUTE: ls -l'
            Be cautious with system-modifying commands and always explain what a command will do before suggesting it."""
        }
        messages.insert(0, system_message)
        messages.append({"role": "user", "content": message})
        
        try:
            response = client.chat.completions.create(
                model="grok-2-1212",
                messages=messages,
                temperature=0.7
            )
            content = response.choices[0].message.content
            
            if "EXECUTE:" in content:
                command_match = re.search(r'EXECUTE:\s*(.+?)(?:\n|$)', content)
                if command_match:
                    command = command_match.group(1).strip()
                    output = execute_command(command)
                    content = f"{content}\n\nCommand output:\n{output}"
            
            # Save the updated context
            messages.append({"role": "assistant", "content": content})
            with open(context_file, 'w') as f:
                json.dump(messages[1:], f)  # Skip system message when saving
            
            return content
        except KeyboardInterrupt:
            return "\nConversation interrupted. Goodbye!"
        except Exception as e:
            return f"Error: {str(e)}"
    except KeyboardInterrupt:
        return "\nConversation interrupted. Goodbye!"

if __name__ == "__main__":
    try:
        if len(sys.argv) != 4:
            print("Usage: chat.py <api_key> <message> <context_file>")
            sys.exit(1)
        
        api_key = sys.argv[1]
        message = sys.argv[2]
        context_file = sys.argv[3]
        
        print(chat(api_key, message, context_file))
    except KeyboardInterrupt:
        print("\nGoodbye!")
        sys.exit(0)
EOF
}

create_requirements_file() {
    cat > "$REQUIREMENTS_FILE" << 'EOF'
openai>=1.0.0
EOF
}

create_grok_script() {
    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONFIG_DIR="/etc/grok_chat"
CONTEXT_FILE="/var/lib/grok/conversation_context"
API_KEY_FILE="$CONFIG_DIR/api_key"
REQUIREMENTS_FILE="$CONFIG_DIR/requirements.txt"

check_dependencies() {
    # Check if Python packages are installed system-wide
    if ! python3 -c "import openai" &> /dev/null; then
        echo -e "${YELLOW}Required Python packages not found. Installing system-wide...${NC}"
        pip3 install --no-cache-dir -r "$REQUIREMENTS_FILE"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install Python dependencies.${NC}"
            exit 1
        fi
    fi
}

show_help() {
    echo -e "${BLUE}Grok Terminal Chat${NC}"
    echo "Usage: grok [OPTION]"
    echo
    echo "Options:"
    echo "  --setup        Initialize or update API key"
    echo "  --rotate-key   Change the API key"
    echo "  --uninstall    Remove Grok Terminal Chat from the system"
    echo "  --help         Display this help message"
    echo
    echo "Without options, the script will start the Grok chat interface"
    echo
    echo "Examples:"
    echo "  grok --setup     # Configure your API key"
    echo "  grok             # Start the chat interface"
    echo "  grok --uninstall # Remove the installation"
}

setup_api_key() {
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    echo -e "${BLUE}API Key Setup${NC}"
    echo "Enter your Grok API key (input will be hidden):"
    read -s api_key
    echo
    
    if [ -z "$api_key" ]; then
        echo -e "${RED}Error: API key cannot be empty${NC}"
        exit 1
    fi
    
    echo "$api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    
    echo -e "${GREEN}API key configured successfully${NC}"
    echo "Note: The actual key is stored securely for future use."
}

case "$1" in
    "--help" | "-h")
        show_help
        exit 0
        ;;
    "--setup" | "-s")
        setup_api_key
        exit 0
        ;;
    "--rotate-key")
        setup_api_key  # Reuse setup_api_key for key rotation
        exit 0
        ;;
    "--uninstall" | "-u")
        echo -e "${RED}Uninstalling Grok Terminal Chat...${NC}"
        read -p "Are you sure you want to uninstall? (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm -f "$INSTALL_DIR/$SCRIPT_NAME"
            rm -rf "$CONFIG_DIR"
            rm -f "$CONTEXT_FILE"
            echo -e "${GREEN}Uninstallation complete${NC}"
        else
            echo -e "${YELLOW}Uninstallation cancelled${NC}"
        fi
        exit 0
        ;;
esac

if [ ! -f "$API_KEY_FILE" ]; then
    echo -e "${RED}API key not configured. Please run 'grok --setup' first.${NC}"
    exit 1
fi

# Check dependencies before proceeding
check_dependencies

api_key=$(cat "$API_KEY_FILE")

if [ ! -f "$CONTEXT_FILE" ]; then
    mkdir -p "/var/lib/grok"
    echo "[]" > "$CONTEXT_FILE"
    chmod 600 "$CONTEXT_FILE"
fi

echo -e "${GREEN}Welcome to Grok Terminal Chat${NC}"
echo "Type 'exit' to quit, 'clear' to reset context"
echo "Press Ctrl+C to exit at any time"

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Goodbye!${NC}"; exit 0' INT

while true; do
    echo -e -n "${YELLOW}You: ${NC}"
    read -r input || { echo -e "\n${GREEN}Goodbye!${NC}"; exit 0; }
    
    if [ "$input" = "exit" ]; then
        echo -e "${GREEN}Goodbye!${NC}"
        break
    elif [ "$input" = "clear" ]; then
        echo "[]" > "$CONTEXT_FILE"
        echo "Context cleared"
        continue
    fi
    
    response=$(python3 "$CONFIG_DIR/chat.py" "$api_key" "$input" "$CONTEXT_FILE")
    echo -e "${BLUE}Grok: ${NC}$response"
done
EOF

    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
}

# Main installation process
echo -e "${GREEN}Starting Grok Terminal Chat installation...${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This installation requires root privileges. Please run with sudo.${NC}"
    exit 1
fi

# Install system dependencies
install_system_deps

# Check for Python 3 after installation attempt
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Failed to install Python 3. Please install it manually.${NC}"
    exit 1
fi

# Check for pip after installation attempt
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}Failed to install pip3. Please install it manually.${NC}"
    exit 1
fi

echo -e "${BLUE}Creating configuration directories...${NC}"
mkdir -p "$CONFIG_DIR"
mkdir -p "/var/lib/grok"

echo -e "${BLUE}Creating requirements file...${NC}"
create_requirements_file

echo -e "${BLUE}Installing Python packages system-wide...${NC}"
pip3 install --no-cache-dir -r "$REQUIREMENTS_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Python dependencies.${NC}"
    exit 1
fi

echo -e "${BLUE}Creating Python script...${NC}"
create_python_script

echo -e "${BLUE}Installing Grok script...${NC}"
create_grok_script

echo -e "${GREEN}Installation complete!${NC}"
echo -e "You can now run Grok Terminal Chat with: ${YELLOW}grok --setup${NC}"
echo -e "Then start chatting with: ${YELLOW}grok${NC}"
