#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# System paths
CONFIG_DIR="${HOME}/.config/grok_chat"
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="grok"
CONTEXT_DIR="${HOME}/.local/share/grok"
CONTEXT_FILE="${CONTEXT_DIR}/conversation_context"
API_KEY_FILE="${CONFIG_DIR}/api_key"
VENV_DIR="${HOME}/.local/share/grok/venv"

# Debug logging
debug_log() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

# Error handling
fail() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Safe directory creation
safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [ -z "$dir" ]; then
        fail "Directory path is empty"
    fi
    
    debug_log "Creating directory: $dir"
    mkdir -p "$dir" || fail "Failed to create directory: $dir"
    chmod "$mode" "$dir" || fail "Failed to set permissions on: $dir"
}

# Detect package manager
detect_package_manager() {
    if command -v apk >/dev/null; then
        echo "apk"
    elif command -v apt-get >/dev/null; then
        echo "apt"
    elif command -v dnf >/dev/null; then
        echo "dnf"
    elif command -v yum >/dev/null; then
        echo "yum"
    elif command -v pacman >/dev/null; then
        echo "pacman"
    elif command -v zypper >/dev/null; then
        echo "zypper"
    else
        fail "No supported package manager found (apk, apt, dnf, yum, pacman, or zypper)"
    fi
}

install_system_deps() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    
    if [ -f /.dockerenv ]; then
        debug_log "Container detected - setting non-interactive modes"
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_MODE=a
    fi

    PKG_MANAGER=$(detect_package_manager)
    debug_log "Detected package manager: $PKG_MANAGER"

    # Check if we have sudo access
    HAS_SUDO=0
    if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
        HAS_SUDO=1
    fi

    # Function to install Python using package manager or alternative methods
    install_python() {
        case "$PKG_MANAGER" in
            apk)
                if [ $HAS_SUDO -eq 1 ]; then
                    sudo apk add python3 py3-pip python3-dev musl-dev
                else
                    debug_log "No sudo access. Please ensure Python 3 and pip are installed"
                    command -v python3 >/dev/null || fail "Python 3 not found"
                    command -v pip3 >/dev/null || fail "pip3 not found"
                fi
                ;;
            apt)
                if [ $HAS_SUDO -eq 1 ]; then
                    sudo apt-get update -q
                    sudo apt-get install -y --no-install-recommends python3 python3-pip python3-venv python3-full
                else
                    debug_log "No sudo access. Please ensure Python 3 and pip are installed"
                    command -v python3 >/dev/null || fail "Python 3 not found"
                    command -v pip3 >/dev/null || fail "pip3 not found"
                fi
                ;;
            dnf|yum)
                if [ $HAS_SUDO -eq 1 ]; then
                    sudo $PKG_MANAGER install -y python3 python3-pip python3-virtualenv
                else
                    debug_log "No sudo access. Please ensure Python 3 and pip are installed"
                    command -v python3 >/dev/null || fail "Python 3 not found"
                    command -v pip3 >/dev/null || fail "pip3 not found"
                fi
                ;;
            pacman)
                if [ $HAS_SUDO -eq 1 ]; then
                    sudo pacman -S --noconfirm python python-pip python-virtualenv
                else
                    debug_log "No sudo access. Please ensure Python 3 and pip are installed"
                    command -v python3 >/dev/null || fail "Python 3 not found"
                    command -v pip3 >/dev/null || fail "pip3 not found"
                fi
                ;;
            zypper)
                if [ $HAS_SUDO -eq 1 ]; then
                    sudo zypper install -y python3 python3-pip python3-virtualenv
                else
                    debug_log "No sudo access. Please ensure Python 3 and pip are installed"
                    command -v python3 >/dev/null || fail "Python 3 not found"
                    command -v pip3 >/dev/null || fail "pip3 not found"
                fi
                ;;
            *)
                debug_log "No supported package manager found. Please ensure Python 3 and pip are installed"
                command -v python3 >/dev/null || fail "Python 3 not found"
                command -v pip3 >/dev/null || fail "pip3 not found"
                ;;
        esac
    }

    install_python
}

# Ensure ~/.local/bin is in PATH
ensure_local_bin_in_path() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

create_python_script() {
    safe_mkdir "$CONFIG_DIR" 750
    
    debug_log "Creating Python chat script"
    cat > "${CONFIG_DIR}/chat.py" << 'PYTHON_EOF'
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
    print(f"\nWould you like to execute this command: {command}")
    confirmation = input("Enter 'yes' to proceed or anything else to cancel: ")
    if confirmation.lower() == 'yes':
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            return result.stdout if result.stdout else result.stderr
        except Exception as e:
            return f"Error executing command: {str(e)}"
    return "Command execution cancelled."

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
            
            # First show the AI's response before executing any commands
            print(content)
            
            if "EXECUTE:" in content:
                command_match = re.search(r'EXECUTE:\s*(.+?)(?:\n|$)', content)
                if command_match:
                    command = command_match.group(1).strip()
                    output = execute_command(command)
                    content += f"\n\nCommand output:\n{output}"
            
            # Save updated context
            messages.append({"role": "assistant", "content": content})
            with open(context_file, 'w') as f:
                json.dump(messages[1:], f)
            
            # Only return the command output if there was one
            if "EXECUTE:" in content:
                return "\nCommand output:\n" + output
            return ""
            
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
        
        result = chat(api_key, message, context_file)
        if result:  # Only print if there's something to print
            print(result)
    except KeyboardInterrupt:
        print("\nGoodbye!")
        sys.exit(0)
PYTHON_EOF

    chmod 640 "${CONFIG_DIR}/chat.py"
}

create_grok_script() {
    safe_mkdir "$INSTALL_DIR" 755
    
    debug_log "Creating main grok executable"
    cat > "${INSTALL_DIR}/${SCRIPT_NAME}" << 'GROK_EOF'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths - using user-specific locations
CONFIG_DIR="${HOME}/.config/grok_chat"
CONTEXT_DIR="${HOME}/.local/share/grok"
CONTEXT_FILE="${CONTEXT_DIR}/conversation_context"
API_KEY_FILE="${CONFIG_DIR}/api_key"
VENV_DIR="${HOME}/.local/share/grok/venv"

# Activate virtual environment
activate_venv() {
    if [ -f "$VENV_DIR/bin/activate" ]; then
        source "$VENV_DIR/bin/activate"
    else
        echo -e "${RED}Virtual environment missing at $VENV_DIR${NC}" >&2
        exit 1
    fi
}

# Dependency check
check_dependencies() {
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${YELLOW}Setting up virtual environment...${NC}" >&2
        python3 -m venv "$VENV_DIR" || {
            echo -e "${RED}Failed to create virtual environment${NC}" >&2
            exit 1
        }
        activate_venv
        pip install --upgrade pip openai || {
            echo -e "${RED}Failed to install Python packages${NC}" >&2
            exit 1
        }
    else
        activate_venv
    fi
}

# Help message
show_help() {
    echo -e "${BLUE}Grok Terminal Chat${NC}"
    echo "Usage: grok [OPTION]"
    echo
    echo "Options:"
    echo "  --setup        Configure API key"
    echo "  --rotate-key   Update API key"
    echo "  --uninstall    Remove Grok"
    echo "  --help         Show this help"
    echo
    echo "Examples:"
    echo "  grok --setup"
    echo "  grok"
}

# API key setup
setup_api_key() {
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    echo -e "${BLUE}API Key Setup${NC}"
    echo -n "Enter your Grok API key (input hidden): "
    read -s api_key
    echo

    if [ -z "$api_key" ]; then
        echo -e "${RED}Error: API key cannot be empty${NC}" >&2
        exit 1
    fi

    echo "$api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    echo -e "${GREEN}API key configured${NC}"
}

# Main command handling
case "$1" in
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
        echo -e "${RED}Uninstalling...${NC}"
        read -p "Confirm (y/n)? " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -f "$HOME/.local/bin/grok"
            rm -rf "$CONFIG_DIR" "$VENV_DIR" "$CONTEXT_DIR"
            echo -e "${GREEN}Uninstalled${NC}"
        else
            echo -e "${YELLOW}Cancelled${NC}"
        fi
        exit 0
        ;;
esac

# Verify API key
if [ ! -f "$API_KEY_FILE" ]; then
    echo -e "${RED}Run 'grok --setup' first${NC}" >&2
    exit 1
fi

# Check dependencies
check_dependencies

# Initialize context
if [ ! -f "$CONTEXT_FILE" ]; then
    mkdir -p "$(dirname "$CONTEXT_FILE")"
    echo "[]" > "$CONTEXT_FILE"
    chmod 600 "$CONTEXT_FILE"
fi

# Main chat loop
echo -e "${GREEN}Grok Terminal Chat${NC}"
echo "Type 'exit' to quit, 'clear' to reset context"
trap 'echo -e "\n${GREEN}Goodbye!${NC}"; exit 0' INT

while true; do
    echo -ne "${YELLOW}You: ${NC}"
    read -r input || { echo -e "\n${GREEN}Goodbye!${NC}"; exit 0; }
    
    case "$input" in
        exit) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        clear)
            echo "[]" > "$CONTEXT_FILE"
            echo "Context cleared"
            continue
            ;;
        *)
            response=$("$VENV_DIR/bin/python" "$CONFIG_DIR/chat.py" \
                      "$(cat "$API_KEY_FILE")" "$input" "$CONTEXT_FILE")
            echo -e "${BLUE}Grok: ${NC}$response"
            ;;
    esac
done
GROK_EOF

    chmod 755 "${INSTALL_DIR}/${SCRIPT_NAME}"
}

setup_virtualenv() {
    safe_mkdir "$(dirname "$VENV_DIR")" 755
    
    debug_log "Creating Python virtual environment at ${VENV_DIR}"
    python3 -m venv "${VENV_DIR}" || fail "Virtual environment creation failed"
    
    # Use absolute path to pip to avoid activation issues
    "${VENV_DIR}/bin/pip" install --upgrade pip || fail "Pip upgrade failed"
    "${VENV_DIR}/bin/pip" install openai || fail "OpenAI package installation failed"
}

main() {
    echo -e "${GREEN}Starting installation...${NC}"
    
    install_system_deps
    command -v python3 >/dev/null || fail "Python 3 not found"
    
    # Ensure ~/.local/bin exists and is in PATH
    ensure_local_bin_in_path
    
    safe_mkdir "$CONTEXT_DIR" 700
    setup_virtualenv
    create_python_script
    create_grok_script
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "Run ${YELLOW}grok --setup${NC} to configure"
    echo -e "Then ${YELLOW}grok${NC} to start chatting"
    echo -e "\nNote: If the 'grok' command is not found, you may need to restart your terminal"
    echo -e "or run: ${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
}

# Pipe-to-bash handling with proper variable passing
if [ ! -t 0 ]; then
    exec bash -c "$(declare -f debug_log fail safe_mkdir detect_package_manager \
                   install_system_deps create_python_script create_grok_script \
                   setup_virtualenv main); \
                   CONFIG_DIR=\"$CONFIG_DIR\" INSTALL_DIR=\"$INSTALL_DIR\" \
                   SCRIPT_NAME=\"$SCRIPT_NAME\" CONTEXT_DIR=\"$CONTEXT_DIR\" \
                   CONTEXT_FILE=\"$CONTEXT_FILE\" API_KEY_FILE=\"$API_KEY_FILE\" \
                   VENV_DIR=\"$VENV_DIR\" main"
else
    main
fi
