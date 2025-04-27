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

# GitHub repository information
REPO_OWNER="lpolish"
REPO_NAME="grok-terminal-chat"
REPO_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

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

# Download file from GitHub
download_file() {
    local url="$1"
    local dest="$2"
    local mode="${3:-644}"
    
    debug_log "Downloading $url to $dest"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest" || fail "Failed to download $url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest" || fail "Failed to download $url"
    else
        fail "Neither curl nor wget is available. Please install one of them."
    fi
    
    chmod "$mode" "$dest" || fail "Failed to set permissions on $dest"
}

# Check if Python is installed
check_python() {
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
        return 1
    fi
    
    # Check Python version
    if ! $PYTHON_CMD -c "import sys; exit(0) if sys.version_info >= (3, 6) else exit(1)"; then
        return 1
    fi
    
    return 0
}

# Install Python if not present
install_python() {
    if check_python; then
        debug_log "Python is already installed"
        return 0
    fi

    echo -e "${YELLOW}Installing Python...${NC}"
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3 python3-pip
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3 python3-pip
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm python python-pip
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add python3 py3-pip
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y python3 python3-pip
    else
        fail "Could not install Python automatically. Please install Python 3.6+ manually."
    fi

    if ! check_python; then
        fail "Python installation failed. Please install Python 3.6+ manually."
    fi
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
    download_file "${BASE_URL}/chat.py" "${CONFIG_DIR}/chat.py" 640
}

create_grok_script() {
    safe_mkdir "$INSTALL_DIR" 755
    download_file "${BASE_URL}/grok.sh" "${INSTALL_DIR}/${SCRIPT_NAME}" 755
}

setup_virtualenv() {
    safe_mkdir "$(dirname "$VENV_DIR")" 755
    
    debug_log "Creating Python virtual environment at ${VENV_DIR}"
    python3 -m venv "${VENV_DIR}" || fail "Virtual environment creation failed"
    
    # Activate virtual environment and install dependencies
    source "${VENV_DIR}/bin/activate" || fail "Failed to activate virtual environment"
    pip install --upgrade pip || fail "Pip upgrade failed"
    pip install openai || fail "OpenAI package installation failed"
    deactivate
}

main() {
    echo -e "${GREEN}Starting installation...${NC}"
    
    install_python
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
    exec bash -c "$(declare -f debug_log fail safe_mkdir download_file check_python install_python \
                   ensure_local_bin_in_path create_python_script create_grok_script \
                   setup_virtualenv main); \
                   CONFIG_DIR=\"$CONFIG_DIR\" INSTALL_DIR=\"$INSTALL_DIR\" \
                   SCRIPT_NAME=\"$SCRIPT_NAME\" CONTEXT_DIR=\"$CONTEXT_DIR\" \
                   CONTEXT_FILE=\"$CONTEXT_FILE\" API_KEY_FILE=\"$API_KEY_FILE\" \
                   VENV_DIR=\"$VENV_DIR\" REPO_OWNER=\"$REPO_OWNER\" \
                   REPO_NAME=\"$REPO_NAME\" REPO_BRANCH=\"$REPO_BRANCH\" \
                   BASE_URL=\"$BASE_URL\" main"
else
    main
fi
