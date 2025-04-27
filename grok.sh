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
