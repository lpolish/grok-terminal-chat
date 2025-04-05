#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="grok"
TEMP_SCRIPT="/tmp/grok_temp_$$"
CONFIG_DIR="$HOME/.grok_chat"
CONFIG_FILE="$CONFIG_DIR/config"
API_KEY_HASH_FILE="$CONFIG_DIR/api_key_hash"
API_KEY_FILE="$CONFIG_DIR/api_key"

show_help() {
    echo -e "${BLUE}Grok Terminal Chat Installer${NC}"
    echo "Usage: grok [OPTION]"
    echo
    echo "Options:"
    echo "  --setup        Initialize or update API key"
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

hash_api_key() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
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
    
    hashed_key=$(hash_api_key "$api_key")
    echo "$hashed_key" > "$API_KEY_HASH_FILE"
    echo "$api_key" > "$CONFIG_DIR/api_key"
    chmod 600 "$API_KEY_HASH_FILE"
    chmod 600 "$CONFIG_DIR/api_key"
    
    echo -e "${GREEN}API key configured successfully${NC}"
    echo "Note: The actual key is stored securely for future use."
}

create_grok_script() {
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash

CONTEXT_FILE="$HOME/.grok_conversation_context"
TEMP_RESPONSE="/tmp/grok_response_$$"
CONFIG_DIR="$HOME/.grok_chat"
API_KEY_HASH_FILE="$CONFIG_DIR/api_key_hash"
API_KEY_FILE="$CONFIG_DIR/api_key"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Grok Terminal Chat${NC}"
    echo "Usage: grok [OPTION]"
    echo
    echo "Options:"
    echo "  --setup        Initialize or update API key"
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
    
    hashed_key=$(hash_api_key "$api_key")
    echo "$hashed_key" > "$API_KEY_HASH_FILE"
    echo "$api_key" > "$CONFIG_DIR/api_key"
    chmod 600 "$API_KEY_HASH_FILE"
    chmod 600 "$CONFIG_DIR/api_key"
    
    echo -e "${GREEN}API key configured successfully${NC}"
    echo "Note: The actual key is stored securely for future use."
}

uninstall() {
    INSTALL_DIR="$HOME/.local/bin"
    SCRIPT_NAME="grok"
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        echo -e "${BLUE}Found $SCRIPT_NAME in $INSTALL_DIR${NC}"
        read -p "Are you sure you want to uninstall Grok Terminal Chat? (y/n): " confirmation
        if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
            rm -f "$INSTALL_DIR/$SCRIPT_NAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Successfully uninstalled $SCRIPT_NAME${NC}"
                
                if [ -d "$CONFIG_DIR" ]; then
                    read -p "Would you like to remove configuration files? (y/n): " config_confirm
                    if [ "$config_confirm" = "y" ] || [ "$config_confirm" = "Y" ]; then
                        rm -rf "$CONFIG_DIR"
                        echo -e "${GREEN}Configuration files removed${NC}"
                    fi
                fi
                
                if [ -f "$CONTEXT_FILE" ]; then
                    read -p "Would you like to remove the conversation context file? (y/n): " context_confirm
                    if [ "$context_confirm" = "y" ] || [ "$context_confirm" = "Y" ]; then
                        rm -f "$CONTEXT_FILE"
                        echo -e "${GREEN}Conversation context file removed${NC}"
                    fi
                fi
                
                echo
                echo "Note: To complete uninstallation, you may want to:"
                echo "1. Remove the PATH entry from ~/.bashrc:"
                echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
                echo "2. Run 'source ~/.bashrc' or restart your terminal"
            else
                echo -e "${RED}Error: Failed to remove $SCRIPT_NAME${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Uninstallation cancelled${NC}"
            exit 0
        fi
    else
        echo -e "${RED}Error: $SCRIPT_NAME not found in $INSTALL_DIR${NC}"
        echo "The script may have been already uninstalled or installed in a different location."
        exit 1
    fi
}

verify_api_key() {
    local input_key="$1"
    if [ ! -f "$API_KEY_HASH_FILE" ]; then
        echo -e "${RED}Error: API key not configured. Run 'grok --setup' first.${NC}"
        exit 1
    fi
    stored_hash=$(cat "$API_KEY_HASH_FILE")
    input_hash=$(hash_api_key "$input_key")
    [ "$stored_hash" = "$input_hash" ]
}

prompt_api_key() {
    if [ ! -f "$API_KEY_HASH_FILE" ]; then
        echo -e "${RED}Error: API key not configured. Run 'grok --setup' first.${NC}"
        exit 1
    fi
    
    if [ -f "$API_KEY_FILE" ]; then
        cat "$API_KEY_FILE"
        return
    fi
    
    echo -e "${BLUE}Enter your Grok API key (input will be hidden):${NC}"
    read -s api_key
    echo
    verify_api_key "$api_key" || {
        echo -e "${RED}Invalid API key${NC}"
        exit 1
    }
    echo "$api_key"
}

send_to_grok() {
    local message="$1"
    local api_key="$2"
    
    echo "Grok: Processing your request: $message" > "$TEMP_RESPONSE"
    
    if [[ "$message" =~ ^(execute|run):(.+)$ ]]; then
        local command="${BASH_REMATCH[2]}"
        if [[ "$command" =~ (rm|delete|mv|move|cp|copy) ]]; then
            echo "Grok: This command ($command) may modify your system. Do you want to proceed? (y/n)" >> "$TEMP_RESPONSE"
            echo "COMMAND:$command" >> "$TEMP_RESPONSE"
        else
            echo "Grok: Executing safe command: $command" >> "$TEMP_RESPONSE"
            echo "OUTPUT:$(eval "$command" 2>&1)" >> "$TEMP_RESPONSE"
        fi
    else
        echo "Grok: I understand: $message" >> "$TEMP_RESPONSE"
        echo "Grok: How can I assist you further?" >> "$TEMP_RESPONSE"
    fi
}

handle_command() {
    local command="$1"
    read -p "Confirm execution of '$command' (y/n): " confirmation
    if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
        echo -e "${GREEN}Executing: $command${NC}"
        eval "$command" 2>&1
    else
        echo -e "${RED}Command execution cancelled${NC}"
    fi
}

case "$1" in
    "--help" | "-h" | "help")
        show_help
        exit 0
        ;;
    "--setup" | "-s" | "setup")
        setup_api_key
        exit 0
        ;;
    "--uninstall" | "-u" | "uninstall")
        uninstall
        exit 0
        ;;
    "")
        ;;
    *)
        echo -e "${RED}Error: Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

[ ! -f "$CONTEXT_FILE" ] && echo "Conversation started on $(date)" > "$CONTEXT_FILE"

echo -e "${BLUE}Welcome to Grok Terminal Chat${NC}"
echo "Type 'exit' to quit, 'clear' to reset context"

api_key=$(prompt_api_key)

while true; do
    echo -ne "${GREEN}You: ${NC}"
    read -r input
    
    case "$input" in
        "exit")
            echo -e "${BLUE}Goodbye${NC}"
            rm -f "$TEMP_RESPONSE"
            break
            ;;
        "clear")
            echo "Conversation started on $(date)" > "$CONTEXT_FILE"
            echo -e "${BLUE}Context cleared${NC}"
            continue
            ;;
        "")
            continue
            ;;
    esac

    echo "You: $input" >> "$CONTEXT_FILE"
    
    send_to_grok "$input" "$api_key"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^COMMAND:(.+)$ ]]; then
            handle_command "${BASH_REMATCH[1]}"
        else
            echo -e "${BLUE}$line${NC}"
        fi
    done < "$TEMP_RESPONSE"
    
    cat "$TEMP_RESPONSE" >> "$CONTEXT_FILE"
    rm -f "$TEMP_RESPONSE"
done
EOF
}

echo -e "${BLUE}Installing Grok Terminal Chat${NC}"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Creating $INSTALL_DIR directory${NC}"
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not create $INSTALL_DIR${NC}"
        exit 1
    fi
fi

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${BLUE}Adding $INSTALL_DIR to PATH in ~/.bashrc${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo -e "${GREEN}Please run 'source ~/.bashrc' after installation or restart your terminal${NC}"
fi

create_grok_script

echo -e "${BLUE}Installing $SCRIPT_NAME to $INSTALL_DIR${NC}"
cp "$TEMP_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to copy script to $INSTALL_DIR${NC}"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to make script executable${NC}"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

rm -f "$TEMP_SCRIPT"

echo -e "${GREEN}Installation completed successfully!${NC}"
echo "1. Configure your API key (optional): $SCRIPT_NAME --setup"
echo "2. Run the chat: $SCRIPT_NAME"
echo "To uninstall, run: $SCRIPT_NAME --uninstall"
echo "If it doesn't work immediately, try:"
echo "  - Running 'source ~/.bashrc' or"
echo "  - Opening a new terminal window"
