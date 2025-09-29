# Yuwathi Proxy

A secure HTTP(S) relay/proxy endpoint with SSL/TLS support for external traffic.

## 🔒 Features

- **HTTPS Support**: Full SSL/TLS encryption for secure communications
- **External Access**: Configurable to accept connections from external IPs
- **JSON API**: Clean REST API for proxy requests
- **Flexible Configuration**: Environment variable support
- **Security Features**: Request validation, size limits, and error handling
- **Multiple Methods**: Support for GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/yuwathi-codeblast/yuwathi-proxy.git
cd yuwathi-proxy

# Create virtual environment
python -m venv env
# On Windows:
.\env\Scripts\activate
# On Linux/Mac:
source env/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Generate SSL Certificates

```bash
# Generate self-signed certificates (for development)
python generate_ssl_cert.py

# Or use OpenSSL directly:
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

### 3. Start the Server

```bash
# Simple start
python app.py

# Or use setup scripts:
# Windows PowerShell:
.\setup-https.ps1 -InstallDeps -GenerateCert -Start

# Linux/Unix:
chmod +x setup-https.sh
./setup-https.sh -i -c -s
```

### Alternative: Automated Setup (Linux)

```bash
# Install system dependencies (Ubuntu/Debian/CentOS/Fedora)
chmod +x install-deps.sh setup-https.sh
./install-deps.sh

# Full setup: install deps, generate certs, start server
./setup-https.sh -i -c -s
```

The server will start on `https://0.0.0.0:8000`

## 📡 API Usage

### Endpoint
```
POST https://your-server:8000/yuwathi/proxy
```

### Request Format
```json
{
  "URL": "https://api.example.com/data",
  "method": "POST",
  "header": {
    "Accept": "application/json",
    "Authorization": "Bearer your-token",
    "Content-Type": "application/json"
  },
  "data": {
    "key": "value"
  },
  "timeout": 30,
  "verify": true,
  "allow_redirects": true
}
```

### Response Format
```json
{
  "status_code": 200,
  "headers": {
    "content-type": "application/json"
  },
  "is_base64": false,
  "body": "response data",
  "truncated": false,
  "reason": "OK"
}
```

### Example with curl
```bash
curl -k -X POST https://localhost:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{
    "URL": "https://api.github.com/zen",
    "method": "GET"
  }'
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
USE_HTTPS=true          # Enable HTTPS (default: true)
HOST=0.0.0.0           # Bind address (default: 0.0.0.0)
PORT=8000              # Port number (default: 8000)
SSL_CERT_PATH=cert.pem # Certificate file path
SSL_KEY_PATH=key.pem   # Private key file path
DEBUG=false            # Debug mode (default: false)
```

## 🔒 SSL Certificates

### Development (Self-signed)
```bash
python generate_ssl_cert.py
```

### Production (Let's Encrypt)
```bash
# Install certbot
pip install certbot

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com

# Update configuration
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem
```

## 🧪 Testing

Run the test suite:
```bash
python test_https.py
```

## 🚀 Production Deployment

### Using Gunicorn (Recommended)
```bash
pip install gunicorn

gunicorn --bind 0.0.0.0:443 \
         --certfile=cert.pem \
         --keyfile=key.pem \
         --workers=4 \
         app:app
```

### Using Systemd Service (Linux)
```bash
# Use the provided installation script
./install-deps.sh

# Or create manually - see LINUX-DEPLOYMENT.md for details
```

## 🛡️ Security

### Important Security Notes
- **Never commit SSL private keys** to version control
- **Use proper certificates** from trusted CAs in production
- **Configure firewalls** appropriately for your use case
- **Monitor logs** for suspicious activity
- **Consider rate limiting** for production deployments

### Features
- Input validation for URLs and methods
- Request size limits (2MB incoming, 5MB response)
- SSL certificate verification options
- Structured error handling and logging

## 📁 Project Structure

```
yuwathi-proxy/
├── app.py                      # Main application
├── requirements.txt            # Python dependencies
├── generate_ssl_cert.py        # SSL certificate generator
├── setup-https.ps1            # Windows setup script
├── setup-https.sh             # Linux/Unix setup script
├── install-deps.sh            # Linux system dependencies installer
├── test_https.py              # Test suite
├── .env.example               # Configuration template
├── README.md                  # This file
├── README-HTTPS.md            # Detailed HTTPS setup guide
├── LINUX-DEPLOYMENT.md        # Linux deployment guide
├── SHELL-SCRIPTS.md           # Shell script documentation
├── SECURITY.md                # Security guidelines
└── .gitignore                 # Git ignore rules
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- Check the [HTTPS Setup Guide](README-HTTPS.md) for detailed configuration
- Review [Security Best Practices](README-HTTPS.md#security-considerations)
- Test your setup with the included test suite

## ⚠️ Disclaimer

This is a development proxy server. For production use:
- Use proper SSL certificates from trusted CAs
- Deploy with a production WSGI server (gunicorn, uWSGI)
- Configure appropriate security measures (firewalls, rate limiting)
- Monitor and log all traffic appropriately