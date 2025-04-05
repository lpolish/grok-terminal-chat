#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Destination directory and script name
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="grok-chat"
TEMP_SCRIPT="/tmp/grok_chat_temp_$$"
CONFIG_DIR="$HOME/.grok_chat"
CONFIG_FILE="$CONFIG_DIR/config"
API_KEY_HASH_FILE="$CONFIG_DIR/api_key_hash"

# Function to display help
show_help() {
    echo -e "${BLUE}Grok Terminal Chat Installer${NC}"
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  --setup        Initialize or update API key"
    echo "  --uninstall    Remove Grok Terminal Chat from the system"
    echo "  --help         Display this help message"
    echo "With no options, the script will install Grok Terminal Chat"
}

# Function to hash API key
hash_api_key() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

# Function to setup API key
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
    
    # Store hashed API key
    hashed_key=$(hash_api_key "$api_key")
    echo "$hashed_key" > "$API_KEY_HASH_FILE"
    chmod 600 "$API_KEY_HASH_FILE"
    
    echo -e "${GREEN}API key configured successfully${NC}"
    echo "Note: The actual key is not stored; only its hash is kept for verification."
}

# Function to verify API key
verify_api_key() {
    local input_key="$1"
    if [ ! -f "$API_KEY_HASH_FILE" ]; then
        echo -e "${RED}Error: API key not configured. Run '$0 --setup' first.${NC}"
        exit 1
    fi
    stored_hash=$(cat "$API_KEY_HASH_FILE")
    input_hash=$(hash_api_key "$input_key")
    [ "$stored_hash" = "$input_hash" ]
}

# Function to create the Grok chat script
create_grok_script() {
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash

# File to store conversation context
CONTEXT_FILE="$HOME/.grok_conversation_context"
TEMP_RESPONSE="/tmp/grok_response_$$"
CONFIG_DIR="$HOME/.grok_chat"
API_KEY_HASH_FILE="$CONFIG_DIR/api_key_hash"

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to hash API key
hash_api_key() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

# Function to verify API key
verify_api_key() {
    local input_key="$1"
    if [ ! -f "$API_KEY_HASH_FILE" ]; then
        echo -e "${RED}Error: API key not configured. Run 'install.sh --setup' first.${NC}"
        exit 1
    fi
    stored_hash=$(cat "$API_KEY_HASH_FILE")
    input_hash=$(hash_api_key "$input_key")
    [ "$stored_hash" = "$input_hash" ]
}

# Function to send message to Grok (placeholder for real API)
send_to_grok() {
    local message="$1"
    local api_key="$2"
    
    # Verify API key
    verify_api_key "$api_key" || {
        echo -e "${RED}Invalid API key${NC}"
        exit 1
    }
    
    # Placeholder for real API call
    # Replace this with actual xAI API integration when available
    echo "Grok: Processing your request: $message" > "$TEMP_RESPONSE"
    
    # Simulated API response logic
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

# Function to handle command confirmation
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

# Initialize context file if it doesn't exist
[ ! -f "$CONTEXT_FILE" ] && echo "Conversation started on $(date)" > "$CONTEXT_FILE"

# Prompt for API key
echo -e "${BLUE}Enter your Grok API key (input will be hidden):${NC}"
read -s api_key
echo

# Main chat loop
echo -e "${BLUE}Welcome to Grok Terminal Chat${NC}"
echo "Type 'exit' to quit, 'clear' to reset context"

while true; do
    echo -ne "${GREEN}You: ${NC}"
    read -r input
    
    # Handle special commands
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

    # Append user input to context
    echo "You: $input" >> "$CONTEXT_FILE"
    
    # Send to Grok and get response
    send_to_grok "$input" "$api_key"
    
    # Display response and handle commands if present
    while IFS= read -r line; do
        if [[ "$line" =~ ^COMMAND:(.+)$ ]]; then
            handle_command "${BASH_REMATCH[1]}"
        else
            echo -e "${BLUE}$line${NC}"
        fi
    done < "$TEMP_RESPONSE"
    
    # Append Grok's response to context
    cat "$TEMP_RESPONSE" >> "$CONTEXT_FILE"
    rm -f "$TEMP_RESPONSE"
done
EOF
}

# Function to uninstall
uninstall() {
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        echo -e "${BLUE}Found $SCRIPT_NAME in $INSTALL_DIR${NC}"
        read -p "Are you sure you want to uninstall Grok Terminal Chat? (y/n): " confirmation
        if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
            rm -f "$INSTALL_DIR/$SCRIPT_NAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Successfully uninstalled $SCRIPT_NAME${NC}"
                echo "Note: This does not remove the PATH entry from ~/.bashrc"
                echo "To remove it manually, edit ~/.bashrc and remove the line:"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
                if [ -d "$CONFIG_DIR" ]; then
                    read -p "Would you also like to remove configuration files? (y/n): " config_confirm
                    if [ "$config_confirm" = "y" ] || [ "$config_confirm" = "Y" ]; then
                        rm -rf "$CONFIG_DIR"
                        echo -e "${GREEN}Configuration files removed${NC}"
                    fi
                fi
                if [ -f "$CONTEXT_FILE" ]; then
                    read -p "Would you also like to remove the conversation context file? (y/n): " context_confirm
                    if [ "$context_confirm" = "y" ] || [ "$context_confirm" = "Y" ]; then
                        rm -f "$CONTEXT_FILE"
                        echo -e "${GREEN}Conversation context file removed${NC}"
                    fi
                fi
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
        exit 1
    fi
}

# Check command line arguments
case "$1" in
    "--help")
        show_help
        exit 0
        ;;
    "--setup")
        setup_api_key
        exit 0
        ;;
    "--uninstall")
        uninstall
        exit 0
        ;;
    "")
        # Proceed with installation
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac

# Installation process
echo -e "${BLUE}Installing Grok Terminal Chat${NC}"

# Create .local/bin if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Creating $INSTALL_DIR directory${NC}"
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not create $INSTALL_DIR${NC}"
        exit 1
    fi
fi

# Check if .local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${BLUE}Adding $INSTALL_DIR to PATH in ~/.bashrc${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo -e "${GREEN}Please run 'source ~/.bashrc' after installation or restart your terminal${NC}"
fi

# Create the script temporarily
create_grok_script

# Install the script
echo -e "${BLUE}Installing $SCRIPT_NAME to $INSTALL_DIR${NC}"
cp "$TEMP_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to copy script to $INSTALL_DIR${NC}"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Make it executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to make script executable${NC}"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Clean up temporary file
rm -f "$TEMP_SCRIPT"

echo -e "${GREEN}Installation completed successfully!${NC}"
echo "1. Configure your API key: $0 --setup"
echo "2. Run the chat: $SCRIPT_NAME"
echo "To uninstall, run: $0 --uninstall"
echo "If it doesn't work immediately, try:"
echo "  - Running 'source ~/.bashrc' or"
echo "  - Opening a new terminal window"