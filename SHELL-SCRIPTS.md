# Shell Scripts for Yuwathi Proxy

This directory contains shell scripts for easy setup and deployment of the Yuwathi HTTPS Proxy.

## 🪟 Windows Scripts

### `setup-https.ps1`
PowerShell script for Windows systems that provides:
- Dependency installation via pip
- SSL certificate generation
- HTTPS server startup
- Configuration options for host/port

**Usage:**
```powershell
# Full setup
.\setup-https.ps1 -InstallDeps -GenerateCert -Start

# Individual operations
.\setup-https.ps1 -GenerateCert    # Generate SSL certificates only
.\setup-https.ps1 -Start           # Start server only
.\setup-https.ps1 -Start -Port 443 # Start on specific port
```

## 🐧 Linux/Unix Scripts

### `setup-https.sh`
Bash script for Linux/Unix systems that provides:
- Python dependency installation
- SSL certificate generation  
- HTTPS server startup
- Flexible configuration options

**Usage:**
```bash
# Make executable
chmod +x setup-https.sh

# Full setup
./setup-https.sh -i -c -s

# Individual operations
./setup-https.sh --cert           # Generate certificates only
./setup-https.sh --start          # Start server only
./setup-https.sh -s -p 443 -h 0.0.0.0  # Custom port/host
```

### `install-deps.sh`
System dependency installer for Linux distributions:
- Automatic OS detection (Ubuntu/Debian/CentOS/RHEL/Fedora/Arch/Alpine)
- System package installation (Python, OpenSSL, curl, git)
- Python virtual environment setup
- Optional firewall configuration
- Optional systemd service creation

**Usage:**
```bash
# Make executable and run
chmod +x install-deps.sh
./install-deps.sh

# Includes interactive prompts for:
# - Firewall configuration
# - Systemd service setup
```

## 📋 Script Features

### Common Features (Both Windows & Linux)
- ✅ **SSL Certificate Generation**: Creates self-signed certificates
- ✅ **Dependency Management**: Installs required Python packages  
- ✅ **Server Startup**: Launches HTTPS proxy with proper configuration
- ✅ **Virtual Environment**: Automatically activates if present
- ✅ **Configuration**: Environment variable support
- ✅ **Error Handling**: Proper error checking and user feedback

### Linux-Specific Features
- ✅ **Multi-Distribution Support**: Works on major Linux distributions
- ✅ **System Package Installation**: Installs OS-level dependencies
- ✅ **Systemd Integration**: Creates system services for auto-start
- ✅ **Firewall Configuration**: Sets up firewall rules automatically
- ✅ **Production Ready**: Includes production deployment options

### Windows-Specific Features
- ✅ **PowerShell Native**: Uses PowerShell cmdlets and features
- ✅ **Administrator Detection**: Checks for elevated privileges
- ✅ **Virtual Environment Detection**: Finds and activates Python venvs
- ✅ **Windows Path Handling**: Proper Windows path management

## 🚀 Quick Start Examples

### Complete Setup (Linux)
```bash
# Clone repository
git clone https://github.com/yuwathi-codeblast/yuwathi-proxy.git
cd yuwathi-proxy

# Make scripts executable  
chmod +x install-deps.sh setup-https.sh

# Install system dependencies
./install-deps.sh

# Setup and start proxy
./setup-https.sh -i -c -s
```

### Complete Setup (Windows)
```powershell
# Clone repository
git clone https://github.com/yuwathi-codeblast/yuwathi-proxy.git
cd yuwathi-proxy

# Run setup script
.\setup-https.ps1 -InstallDeps -GenerateCert -Start
```

## 🔧 Customization

### Environment Variables
Both scripts respect these environment variables:
- `USE_HTTPS=true` - Enable HTTPS mode
- `HOST=0.0.0.0` - Bind address  
- `PORT=8000` - Listen port
- `SSL_CERT_PATH=cert.pem` - Certificate file path
- `SSL_KEY_PATH=key.pem` - Private key file path

### Script Options
All scripts include `--help` options for detailed usage information:
```bash
./setup-https.sh --help
./install-deps.sh --help
```

```powershell
Get-Help .\setup-https.ps1 -Detailed
```

## 📚 Additional Documentation

- **README.md** - Main project documentation
- **LINUX-DEPLOYMENT.md** - Comprehensive Linux deployment guide
- **README-HTTPS.md** - Detailed HTTPS configuration guide
- **SECURITY.md** - Security best practices and guidelines

## 🔒 Security Notes

- Scripts generate **self-signed certificates** by default (development use)
- For production, replace with certificates from trusted Certificate Authorities
- Review generated configurations before deploying to production
- Follow security guidelines in SECURITY.md

## 🐛 Troubleshooting

### Common Issues
1. **Permission denied**: Make scripts executable with `chmod +x`
2. **Port already in use**: Check for existing services on the port
3. **SSL certificate errors**: Regenerate certificates or check file permissions
4. **Python not found**: Ensure Python 3.7+ is installed and in PATH

### Getting Help
- Check script help: `./setup-https.sh --help`
- Review logs: Scripts provide detailed error messages
- See LINUX-DEPLOYMENT.md for comprehensive troubleshooting
- Check systemd logs: `sudo journalctl -u yuwathi-proxy -f`