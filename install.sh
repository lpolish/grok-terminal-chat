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
    
    debug_log "Copying Python chat script"
    # Get the directory where the install script is located
    local script_dir
    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Copy the chat.py script from the source directory
    cp "${script_dir}/chat.py" "${CONFIG_DIR}/chat.py" || fail "Failed to copy chat.py"

    chmod 640 "${CONFIG_DIR}/chat.py"
}

create_grok_script() {
    safe_mkdir "$INSTALL_DIR" 755
    
    debug_log "Copying main grok executable"
    # Get the directory where the install script is located
    local script_dir
    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    # Copy the grok.sh script from the source directory
    cp "${script_dir}/grok.sh" "${INSTALL_DIR}/${SCRIPT_NAME}" || fail "Failed to copy grok.sh"

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
