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

# Debug logging
debug_log() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

# Error handling
fail() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Install system dependencies with verbose output
install_system_deps() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    
    # Check if we're running in a container
    if [ -f /.dockerenv ]; then
        debug_log "Running in Docker container"
        export DEBIAN_FRONTEND=noninteractive
        export NEEDRESTART_MODE=a
    fi

    # Store package manager output in a temporary file
    PM_LOG=$(mktemp)
    trap 'rm -f "$PM_LOG"' EXIT

    debug_log "Updating package lists"
    if ! { apt-get update -q 2>&1 | tee -a "$PM_LOG"; }; then
        fail "Failed to update package lists:\n$(cat "$PM_LOG")"
    fi

    debug_log "Installing required packages"
    if ! { apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-full \
        2>&1 | tee -a "$PM_LOG"; }; then
        fail "Failed to install packages:\n$(cat "$PM_LOG")"
    fi

    debug_log "System dependencies installed successfully"
    rm -f "$PM_LOG"
}

create_python_script() {
    debug_log "Creating Python script at $CONFIG_DIR/chat.py"
    mkdir -p "$CONFIG_DIR" || fail "Failed to create config directory"
    
    cat > "$CONFIG_DIR/chat.py" << 'EOF'
[Previous Python script content remains exactly the same]
EOF

    chmod 644 "$CONFIG_DIR/chat.py" || fail "Failed to set permissions for chat.py"
}

create_grok_script() {
    debug_log "Creating main grok script at $INSTALL_DIR/$SCRIPT_NAME"
    mkdir -p "$INSTALL_DIR" || fail "Failed to create install directory"
    
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << EOF
[Previous grok script content remains the same, 
but ensure all paths use the system-wide locations]
EOF

    chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || fail "Failed to make grok executable"
}

setup_virtualenv() {
    debug_log "Setting up Python virtual environment at $VENV_DIR"
    
    if ! python3 -m venv "$VENV_DIR"; then
        fail "Failed to create virtual environment"
    fi

    # Activate and install packages
    if ! (
        source "$VENV_DIR/bin/activate" && \
        pip install --upgrade pip && \
        pip install openai>=1.0.0
    ); then
        fail "Failed to install Python packages in virtual environment"
    fi

    debug_log "Virtual environment setup complete"
}

# Main installation process
main() {
    echo -e "${GREEN}Starting Grok Terminal Chat installation${NC}"
    
    # Check root
    if [ "$(id -u)" -ne 0 ]; then
        fail "This installation requires root privileges. Please run with sudo."
    fi

    # Install system dependencies (with verbose output)
    install_system_deps

    # Verify Python is available
    if ! command -v python3 >/dev/null 2>&1; then
        fail "Python 3 is not available after installation"
    fi

    # Create necessary directories
    debug_log "Creating system directories"
    mkdir -p "$CONFIG_DIR" "/var/lib/grok" "$(dirname "$VENV_DIR")" || \
        fail "Failed to create system directories"
    chmod 755 "$CONFIG_DIR" "/var/lib/grok" || \
        fail "Failed to set directory permissions"

    # Setup virtual environment
    setup_virtualenv

    # Create the scripts
    create_python_script
    create_grok_script

    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo
    echo -e "To set up your API key: ${YELLOW}grok --setup${NC}"
    echo -e "To start chatting: ${YELLOW}grok${NC}"
    echo
    echo -e "For uninstallation: ${YELLOW}grok --uninstall${NC}"
}

# Special handling for pipe-to-bash
if [ ! -t 0 ]; then
    debug_log "Running in pipe-to-bash mode"
    # Use exec to replace current process and properly handle the pipe
    exec bash -c "$(declare -f debug_log fail install_system_deps create_python_script create_grok_script setup_virtualenv main); main" || \
        fail "Installation failed during pipe execution"
else
    # Normal interactive execution
    main
fi
