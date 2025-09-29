#!/bin/bash

# Yuwathi Proxy - System Dependencies Installation Script
# Supports Ubuntu/Debian, CentOS/RHEL/Fedora, and other common distributions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    print_color $CYAN "🔧 Yuwathi Proxy - System Dependencies Installer"
    print_color $CYAN "==============================================="
}

# Detect the operating system
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        DISTRO=$ID
    elif [[ -f /etc/redhat-release ]]; then
        OS=$(cat /etc/redhat-release)
        DISTRO="rhel"
    else
        OS=$(uname -s)
        DISTRO="unknown"
    fi
    
    print_color $BLUE "Detected OS: $OS"
}

# Check if running as root for system package installation
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_color $YELLOW "⚠️  Running as root. This is fine for system package installation."
    else
        print_color $YELLOW "⚠️  Not running as root. You may need sudo privileges for package installation."
    fi
}

# Install system dependencies based on distribution
install_system_deps() {
    print_color $YELLOW "📦 Installing system dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            print_color $BLUE "Using apt package manager..."
            sudo apt update
            sudo apt install -y python3 python3-pip python3-venv openssl curl wget git
            ;;
        fedora)
            print_color $BLUE "Using dnf package manager..."
            sudo dnf update -y
            sudo dnf install -y python3 python3-pip openssl curl wget git
            ;;
        centos|rhel)
            print_color $BLUE "Using yum package manager..."
            sudo yum update -y
            sudo yum install -y python3 python3-pip openssl curl wget git
            ;;
        arch)
            print_color $BLUE "Using pacman package manager..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm python python-pip openssl curl wget git
            ;;
        alpine)
            print_color $BLUE "Using apk package manager..."
            sudo apk update
            sudo apk add python3 py3-pip openssl curl wget git
            ;;
        *)
            print_color $RED "❌ Unsupported distribution: $DISTRO"
            print_color $YELLOW "Please install the following packages manually:"
            print_color $YELLOW "  - Python 3.7+"
            print_color $YELLOW "  - pip (Python package manager)"
            print_color $YELLOW "  - openssl"
            print_color $YELLOW "  - curl"
            print_color $YELLOW "  - git"
            exit 1
            ;;
    esac
    
    print_color $GREEN "✅ System dependencies installed successfully!"
}

# Install Python dependencies
install_python_deps() {
    print_color $YELLOW "🐍 Setting up Python environment..."
    
    # Create virtual environment
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
        print_color $GREEN "✅ Virtual environment created: venv/"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
        print_color $GREEN "✅ Python dependencies installed successfully!"
    else
        print_color $YELLOW "⚠️  requirements.txt not found. Installing basic dependencies..."
        pip install flask requests cryptography python-dotenv
        print_color $GREEN "✅ Basic Python dependencies installed!"
    fi
}

# Setup firewall rules
setup_firewall() {
    local PORT=${1:-8000}
    
    print_color $YELLOW "🔥 Configuring firewall for port $PORT..."
    
    # Check if ufw is available (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        print_color $BLUE "Using ufw firewall..."
        if sudo ufw status | grep -q "Status: active"; then
            sudo ufw allow $PORT/tcp
            print_color $GREEN "✅ ufw rule added for port $PORT"
        else
            print_color $YELLOW "⚠️  ufw is not active. To enable it run: sudo ufw enable"
        fi
    # Check if firewall-cmd is available (CentOS/RHEL/Fedora)
    elif command -v firewall-cmd &> /dev/null; then
        print_color $BLUE "Using firewalld..."
        if systemctl is-active --quiet firewalld; then
            sudo firewall-cmd --permanent --add-port=$PORT/tcp
            sudo firewall-cmd --reload
            print_color $GREEN "✅ firewalld rule added for port $PORT"
        else
            print_color $YELLOW "⚠️  firewalld is not active"
        fi
    # Check if iptables is available
    elif command -v iptables &> /dev/null; then
        print_color $BLUE "Using iptables..."
        sudo iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        print_color $GREEN "✅ iptables rule added for port $PORT"
        print_color $YELLOW "⚠️  Note: iptables rules are not persistent. Consider using iptables-persistent."
    else
        print_color $YELLOW "⚠️  No known firewall found. Please configure manually if needed."
    fi
}

# Create systemd service file
create_service() {
    local SERVICE_NAME="yuwathi-proxy"
    local WORK_DIR=$(pwd)
    local USER=$(whoami)
    
    print_color $YELLOW "⚙️  Creating systemd service..."
    
    cat > /tmp/${SERVICE_NAME}.service << EOF
[Unit]
Description=Yuwathi HTTPS Proxy Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORK_DIR
Environment=USE_HTTPS=true
Environment=HOST=0.0.0.0
Environment=PORT=8000
ExecStart=$WORK_DIR/venv/bin/python $WORK_DIR/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    sudo mv /tmp/${SERVICE_NAME}.service /etc/systemd/system/
    sudo systemctl daemon-reload
    
    print_color $GREEN "✅ Systemd service created: $SERVICE_NAME"
    print_color $CYAN "To manage the service:"
    print_color $CYAN "  sudo systemctl start $SERVICE_NAME    # Start service"
    print_color $CYAN "  sudo systemctl enable $SERVICE_NAME   # Enable on boot"
    print_color $CYAN "  sudo systemctl status $SERVICE_NAME   # Check status"
    print_color $CYAN "  sudo journalctl -u $SERVICE_NAME -f   # View logs"
}

# Main installation function
main() {
    print_header
    
    detect_os
    check_root
    
    echo
    print_color $CYAN "This script will install:"
    echo "  - Python 3 and pip"
    echo "  - OpenSSL"
    echo "  - Git and curl"
    echo "  - Python virtual environment"
    echo "  - Required Python packages"
    echo "  - Optional: Firewall configuration"
    echo "  - Optional: Systemd service"
    
    echo
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Installation cancelled."
        exit 0
    fi
    
    echo
    install_system_deps
    echo
    install_python_deps
    
    echo
    read -p "Configure firewall for port 8000? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_firewall 8000
    fi
    
    echo
    read -p "Create systemd service for auto-start? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_service
    fi
    
    echo
    print_color $GREEN "🎉 Installation completed successfully!"
    echo
    print_color $CYAN "Next steps:"
    echo "1. Generate SSL certificates: ./setup-https.sh -c"
    echo "2. Start the server: ./setup-https.sh -s"
    echo "3. Or use the service: sudo systemctl start yuwathi-proxy"
    echo
    print_color $CYAN "For more options: ./setup-https.sh --help"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        print_header
        echo
        echo "System dependencies installation script for Yuwathi Proxy"
        echo
        echo "Usage: ./install-deps.sh [OPTIONS]"
        echo
        echo "This script will install:"
        echo "  - Python 3 and pip"
        echo "  - OpenSSL for SSL certificate generation"
        echo "  - Git and curl utilities"
        echo "  - Python virtual environment and packages"
        echo "  - Optional firewall configuration"
        echo "  - Optional systemd service setup"
        echo
        echo "Supported distributions:"
        echo "  - Ubuntu/Debian (apt)"
        echo "  - CentOS/RHEL (yum)"
        echo "  - Fedora (dnf)"
        echo "  - Arch Linux (pacman)"
        echo "  - Alpine Linux (apk)"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac