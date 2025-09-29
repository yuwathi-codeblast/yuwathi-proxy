#!/bin/bash

# Yuwathi Proxy HTTPS Setup Script for Linux/Unix
# This script will help you set up HTTPS for your Flask proxy

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
PORT="8000"
HOST="0.0.0.0"
GENERATE_CERT=false
INSTALL_DEPS=false
START_SERVER=false

# Function to print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    print_color $CYAN "🔒 Yuwathi Proxy HTTPS Setup"
    print_color $CYAN "==============================="
}

# Function to show usage
show_usage() {
    echo ""
    print_color $CYAN "Usage:"
    echo "  ./setup-https.sh [OPTIONS]"
    echo ""
    print_color $CYAN "Options:"
    echo "  -c, --cert          Generate SSL certificates"
    echo "  -i, --install       Install Python dependencies"
    echo "  -s, --start         Start HTTPS server"
    echo "  -p, --port PORT     Port to listen on (default: 8000)"
    echo "  -h, --host HOST     Host to bind to (default: 0.0.0.0)"
    echo "  --help              Show this help message"
    echo ""
    print_color $CYAN "Examples:"
    echo "  ./setup-https.sh -i -c -s                    # Full setup and start"
    echo "  ./setup-https.sh --install --cert --start    # Same as above"
    echo "  ./setup-https.sh -s -p 443 -h localhost      # Start on port 443, localhost only"
    echo "  ./setup-https.sh -c                          # Generate certificates only"
    echo ""
    print_color $CYAN "Manual steps:"
    echo "1. Install dependencies: pip install -r requirements.txt"
    echo "2. Generate certificates: python generate_ssl_cert.py"
    echo "3. Start server: python app.py"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cert)
            GENERATE_CERT=true
            shift
            ;;
        -i|--install)
            INSTALL_DEPS=true
            shift
            ;;
        -s|--start)
            START_SERVER=true
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        --help)
            print_header
            show_usage
            exit 0
            ;;
        *)
            print_color $RED "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if running as root for privileged ports
check_privileges() {
    if [[ $PORT -lt 1024 && $EUID -ne 0 ]]; then
        print_color $YELLOW "⚠️  Warning: Port $PORT requires root privileges."
        print_color $YELLOW "   You may need to run with sudo or use a port >= 1024"
    fi
}

# Check if Python is available
check_python() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        print_color $RED "❌ Python is not installed or not in PATH"
        print_color $YELLOW "   Please install Python 3.7+ and try again"
        exit 1
    fi
    
    # Prefer python3 if available
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
}

# Check if pip is available
check_pip() {
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        print_color $RED "❌ pip is not installed or not in PATH"
        print_color $YELLOW "   Please install pip and try again"
        exit 1
    fi
    
    # Prefer pip3 if available
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    else
        PIP_CMD="pip"
    fi
}

# Function to activate virtual environment if it exists
activate_venv() {
    if [[ -f "venv/bin/activate" ]]; then
        print_color $GREEN "Activating virtual environment (venv)..."
        source venv/bin/activate
    elif [[ -f "env/bin/activate" ]]; then
        print_color $GREEN "Activating virtual environment (env)..."
        source env/bin/activate
    elif [[ -f ".venv/bin/activate" ]]; then
        print_color $GREEN "Activating virtual environment (.venv)..."
        source .venv/bin/activate
    else
        print_color $YELLOW "⚠️  No virtual environment found. Using system Python."
        print_color $YELLOW "   Consider creating one with: python3 -m venv venv"
    fi
}

# Install dependencies
install_dependencies() {
    print_color $YELLOW "📦 Installing Python dependencies..."
    
    check_python
    check_pip
    activate_venv
    
    if [[ ! -f "requirements.txt" ]]; then
        print_color $RED "❌ requirements.txt not found"
        exit 1
    fi
    
    $PIP_CMD install -r requirements.txt
    
    if [[ $? -eq 0 ]]; then
        print_color $GREEN "✅ Dependencies installed successfully!"
    else
        print_color $RED "❌ Failed to install dependencies"
        exit 1
    fi
}

# Generate SSL certificates
generate_certificates() {
    print_color $YELLOW "🔐 Generating SSL certificates..."
    
    check_python
    activate_venv
    
    if [[ -f "cert.pem" && -f "key.pem" ]]; then
        print_color $YELLOW "SSL certificates already exist."
        read -p "Overwrite existing certificates? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color $YELLOW "Keeping existing certificates."
            return 0
        fi
        rm -f cert.pem key.pem
    fi
    
    if [[ ! -f "generate_ssl_cert.py" ]]; then
        print_color $RED "❌ generate_ssl_cert.py not found"
        exit 1
    fi
    
    $PYTHON_CMD generate_ssl_cert.py
    
    if [[ $? -eq 0 && -f "cert.pem" && -f "key.pem" ]]; then
        print_color $GREEN "✅ SSL certificates generated successfully!"
        print_color $GREEN "   Certificate: cert.pem"
        print_color $GREEN "   Private Key: key.pem"
        print_color $GREEN "   Valid for: 365 days from today"
        echo
        print_color $YELLOW "⚠️  WARNING: This is a self-signed certificate!"
        print_color $YELLOW "   Browsers will show security warnings."
        print_color $YELLOW "   For production, use certificates from a trusted CA."
    else
        print_color $RED "❌ Failed to generate SSL certificates"
        exit 1
    fi
}

# Start the server
start_server() {
    print_color $YELLOW "🚀 Starting HTTPS proxy server..."
    
    check_python
    check_privileges
    activate_venv
    
    # Check if certificates exist
    if [[ ! -f "cert.pem" || ! -f "key.pem" ]]; then
        print_color $YELLOW "⚠️  SSL certificates not found. Generating them first..."
        generate_certificates
    fi
    
    if [[ ! -f "app.py" ]]; then
        print_color $RED "❌ app.py not found"
        exit 1
    fi
    
    # Set environment variables
    export USE_HTTPS=true
    export HOST=$HOST
    export PORT=$PORT
    
    print_color $GREEN "Server will start on: https://$HOST:$PORT"
    print_color $GREEN "Proxy endpoint: https://$HOST:$PORT/yuwathi/proxy"
    echo
    print_color $YELLOW "Press Ctrl+C to stop the server"
    echo
    
    # Start the server
    $PYTHON_CMD app.py
}

# Function to create virtual environment
create_venv() {
    print_color $YELLOW "📦 Creating virtual environment..."
    
    check_python
    
    if [[ ! -d "venv" && ! -d "env" && ! -d ".venv" ]]; then
        $PYTHON_CMD -m venv venv
        print_color $GREEN "✅ Virtual environment created: venv/"
        print_color $CYAN "   Activate it with: source venv/bin/activate"
    else
        print_color $YELLOW "Virtual environment already exists."
    fi
}

# Function to run tests
run_tests() {
    print_color $YELLOW "🧪 Running HTTPS tests..."
    
    check_python
    activate_venv
    
    if [[ -f "test_https.py" ]]; then
        $PYTHON_CMD test_https.py
    else
        print_color $RED "❌ test_https.py not found"
        exit 1
    fi
}

# Function to show server status
show_status() {
    print_color $CYAN "📊 Server Status"
    print_color $CYAN "================"
    
    if command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$PORT "; then
            print_color $GREEN "✅ Port $PORT is in use (server may be running)"
        else
            print_color $YELLOW "⚠️  Port $PORT is not in use"
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$PORT "; then
            print_color $GREEN "✅ Port $PORT is in use (server may be running)"
        else
            print_color $YELLOW "⚠️  Port $PORT is not in use"
        fi
    else
        print_color $YELLOW "⚠️  Cannot check port status (ss/netstat not available)"
    fi
    
    if [[ -f "cert.pem" && -f "key.pem" ]]; then
        print_color $GREEN "✅ SSL certificates found"
        
        # Show certificate info if openssl is available
        if command -v openssl &> /dev/null; then
            echo
            print_color $CYAN "Certificate Information:"
            openssl x509 -in cert.pem -text -noout | grep -E "(Subject:|Not Before:|Not After:|DNS:|IP Address:)" || true
        fi
    else
        print_color $RED "❌ SSL certificates not found"
    fi
}

# Main script logic
main() {
    print_header
    
    # If no arguments provided, show help
    if [[ $GENERATE_CERT == false && $INSTALL_DEPS == false && $START_SERVER == false ]]; then
        show_usage
        echo
        print_color $CYAN "Quick setup options:"
        echo "  ./setup-https.sh -i -c -s    # Install deps, generate certs, start server"
        echo "  ./setup-https.sh --help      # Show detailed help"
        exit 0
    fi
    
    # Execute requested operations
    if [[ $INSTALL_DEPS == true ]]; then
        install_dependencies
        echo
    fi
    
    if [[ $GENERATE_CERT == true ]]; then
        generate_certificates
        echo
    fi
    
    if [[ $START_SERVER == true ]]; then
        start_server
    fi
}

# Additional functions for convenience
case "${1:-}" in
    "venv")
        print_header
        create_venv
        exit 0
        ;;
    "test")
        print_header
        run_tests
        exit 0
        ;;
    "status")
        print_header
        show_status
        exit 0
        ;;
esac

# Run main function
main "$@"