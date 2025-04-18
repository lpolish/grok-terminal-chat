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
VENV_DIR="/opt/grok_venv"

# Function to install system dependencies
install_system_deps() {
    echo -e "${BLUE}Installing system dependencies...${NC}"
    
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y python3 python3-pip python3-venv python3-full
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

[Previous Python script content remains exactly the same]
EOF
}

create_requirements_file() {
    cat > "$REQUIREMENTS_FILE" << 'EOF'
openai>=1.0.0
EOF
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
REQUIREMENTS_FILE="$REQUIREMENTS_FILE"
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
    # Check if virtual environment exists
    if [ ! -d "\$VENV_DIR" ]; then
        echo -e "\${YELLOW}Creating Python virtual environment...\${NC}"
        python3 -m venv "\$VENV_DIR"
        activate_venv
        pip install --upgrade pip
        pip install -r "\$REQUIREMENTS_FILE"
        if [ \$? -ne 0 ]; then
            echo -e "\${RED}Failed to install Python dependencies.\${NC}"
            exit 1
        fi
    else
        activate_venv
    fi
}

[Rest of the previous bash script content remains the same, just replace the python3 calls with the proper venv path]
EOF

    # Replace python3 calls with venv python in the installed script
    sed -i 's|python3|'"$VENV_DIR"'/bin/python3|g' "$INSTALL_DIR/$SCRIPT_NAME"
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

echo -e "${BLUE}Creating configuration directories...${NC}"
mkdir -p "$CONFIG_DIR"
mkdir -p "/var/lib/grok"
mkdir -p "$VENV_DIR"

echo -e "${BLUE}Creating requirements file...${NC}"
create_requirements_file

echo -e "${BLUE}Creating Python virtual environment...${NC}"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo -e "${BLUE}Installing Python packages in virtual environment...${NC}"
pip install -r "$REQUIREMENTS_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Python dependencies.${NC}"
    exit 1
fi
deactivate

echo -e "${BLUE}Creating Python script...${NC}"
create_python_script

echo -e "${BLUE}Installing Grok script...${NC}"
create_grok_script

echo -e "${GREEN}Installation complete!${NC}"
echo -e "You can now run Grok Terminal Chat with: ${YELLOW}grok --setup${NC}"
echo -e "Then start chatting with: ${YELLOW}grok${NC}"
