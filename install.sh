#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# System paths
CONFIG_DIR="/etc/grok_chat"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="grok"
CONTEXT_FILE="/var/lib/grok/conversation_context"
API_KEY_FILE="$CONFIG_DIR/api_key"
VENV_DIR="/opt/grok_venv"

# Ensure clean execution in pipes
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Function to install system dependencies
install_system_deps() {
    echo -e "${BLUE}Installing system dependencies...${NC}"
    
    # Create temp file for apt output
    APT_LOG=$(mktemp)
    
    # Run apt commands with forced non-interactive mode
    {
        apt-get update -q
        apt-get install -yq --no-install-recommends \
            python3 \
            python3-pip \
            python3-venv \
            python3-full \
            ca-certificates
    } > "$APT_LOG" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install system dependencies. Log:${NC}"
        cat "$APT_LOG"
        rm -f "$APT_LOG"
        exit 1
    fi
    rm -f "$APT_LOG"
}

create_python_script() {
    mkdir -p "$CONFIG_DIR"
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
    chmod 644 "$CONFIG_DIR/chat.py"
}

create_grok_script() {
    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << EOF
#!/bin/bash

RED='\\033[0;31m'
GREEN='\\033[0;32m'
BLUE='\\033[0;34m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

CONFIG_DIR="$CONFIG_DIR"
CONTEXT_FILE="$CONTEXT_FILE"
API_KEY_FILE="$API_KEY_FILE"
VENV_DIR="$VENV_DIR"

activate_venv() {
    if [ -f "\$VENV_DIR/bin/activate" ]; then
        source "\$VENV_DIR/bin/activate"
    else
        echo -e "\${RED}Virtual environment not found at \$VENV_DIR\${NC}"
        exit 1
    fi
}

check_dependencies() {
    if [ ! -d "\$VENV_DIR" ]; then
        echo -e "\${YELLOW}Creating Python virtual environment...\${NC}"
        python3 -m venv "\$VENV_DIR" || {
            echo -e "\${RED}Failed to create virtual environment\${NC}"
            exit 1
        }
        activate_venv
        pip install --upgrade pip || {
            echo -e "\${RED}Failed to upgrade pip\${NC}"
            exit 1
        }
        pip install openai>=1.0.0 || {
            echo -e "\${RED}Failed to install Python dependencies\${NC}"
            exit 1
        }
    else
        activate_venv
    fi
}

show_help() {
    echo -e "\${BLUE}Grok Terminal Chat\${NC}"
    echo "Usage: grok [OPTION]"
    echo
    echo "Options:"
    echo "  --setup        Initialize or update API key"
    echo "  --rotate-key   Change the API key"
    echo "  --uninstall    Remove Grok Terminal Chat"
    echo "  --help         Display this help"
    echo
    echo "Examples:"
    echo "  grok --setup     # Configure API key"
    echo "  grok             # Start chat"
}

setup_api_key() {
    mkdir -p "\$CONFIG_DIR"
    chmod 700 "\$CONFIG_DIR"
    
    echo -e "\${BLUE}API Key Setup\${NC}"
    echo "Enter your Grok API key (input will be hidden):"
    read -s api_key
    echo
    
    if [ -z "\$api_key" ]; then
        echo -e "\${RED}Error: API key cannot be empty\${NC}"
        exit 1
    fi
    
    echo "\$api_key" > "\$API_KEY_FILE"
    chmod 600 "\$API_KEY_FILE"
    echo -e "\${GREEN}API key configured successfully\${NC}"
}

case "\$1" in
    "--help"|"-h")
        show_help
        exit 0
        ;;
    "--setup"|"-s")
        setup_api_key
        exit 0
        ;;
    "--rotate-key")
        setup_api_key
        exit 0
        ;;
    "--uninstall"|"-u")
        echo -e "\${RED}Uninstalling...\${NC}"
        read -p "Are you sure? (y/n): " confirm
        if [ "\$confirm" = "y" ] || [ "\$confirm" = "Y" ]; then
            rm -f "$INSTALL_DIR/$SCRIPT_NAME"
            rm -rf "\$CONFIG_DIR" "\$VENV_DIR" "\$CONTEXT_FILE"
            echo -e "\${GREEN}Uninstallation complete\${NC}"
        else
            echo -e "\${YELLOW}Uninstallation cancelled\${NC}"
        fi
        exit 0
        ;;
esac

if [ ! -f "\$API_KEY_FILE" ]; then
    echo -e "\${RED}API key not configured. Run 'grok --setup'\${NC}"
    exit 1
fi

check_dependencies

api_key=\$(cat "\$API_KEY_FILE")

if [ ! -f "\$CONTEXT_FILE" ]; then
    mkdir -p \$(dirname "\$CONTEXT_FILE")
    echo "[]" > "\$CONTEXT_FILE"
    chmod 600 "\$CONTEXT_FILE"
fi

echo -e "\${GREEN}Welcome to Grok Terminal Chat\${NC}"
echo "Type 'exit' to quit, 'clear' to reset context"

trap 'echo -e "\n\${GREEN}Goodbye!\${NC}"; exit 0' INT

while true; do
    echo -e -n "\${YELLOW}You: \${NC}"
    read -r input || { echo -e "\n\${GREEN}Goodbye!\${NC}"; exit 0; }
    
    if [ "\$input" = "exit" ]; then
        echo -e "\${GREEN}Goodbye!\${NC}"
        break
    elif [ "\$input" = "clear" ]; then
        echo "[]" > "\$CONTEXT_FILE"
        echo "Context cleared"
        continue
    fi
    
    response=\$("\$VENV_DIR/bin/python3" "\$CONFIG_DIR/chat.py" "\$api_key" "\$input" "\$CONTEXT_FILE")
    echo -e "\${BLUE}Grok: \${NC}\$response"
done
EOF
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
}

# Main installation
{
    echo -e "${GREEN}Starting Grok Terminal Chat installation...${NC}"
    
    # Check root
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
    
    # Special handling for pipe-to-bash
    if [ ! -t 0 ]; then
        echo -e "${YELLOW}Running in non-interactive mode${NC}"
        exec bash -c "$(declare -f install_system_deps); install_system_deps"
    else
        install_system_deps
    fi
    
    # Verify Python
    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}Python 3 installation failed${NC}"
        exit 1
    fi
    
    # Create directories
    mkdir -p "$CONFIG_DIR" "/var/lib/grok" "$(dirname "$VENV_DIR")"
    chmod 755 "$CONFIG_DIR" "/var/lib/grok"
    
    # Create virtual environment
    python3 -m venv "$VENV_DIR" || {
        echo -e "${RED}Failed to create virtual environment${NC}"
        exit 1
    }
    
    # Install Python packages
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip || {
        echo -e "${RED}Failed to upgrade pip${NC}"
        exit 1
    }
    pip install openai>=1.0.0 || {
        echo -e "${RED}Failed to install Python packages${NC}"
        exit 1
    }
    deactivate
    
    # Create scripts
    create_python_script
    create_grok_script
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "Run: ${YELLOW}grok --setup${NC} to configure API key"
    echo -e "Then: ${YELLOW}grok${NC} to start chatting"
} || {
    echo -e "${RED}Installation failed${NC}"
    exit 1
}
