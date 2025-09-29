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
python3 -m venv env
source env/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Generate SSL Certificates

```bash
# Generate self-signed certificates (for development)
python3 generate_ssl_cert.py

# Or use OpenSSL directly:
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

### 3. Start the Server

```bash
# Simple start
python3 app.py

# Or use setup scripts:
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

## ☁️ Google Cloud Platform (GCP) Deployment

### 1. Compute Engine Setup

```bash
# Connect to your GCP VM instance
gcloud compute ssh your-instance-name --zone=your-zone

# Or via the web console SSH button
```

### 2. Configure GCP Firewall Rules

```bash
# Create firewall rule to allow traffic on port 8000
gcloud compute firewall-rules create allow-yuwathi-proxy \
    --allow tcp:8000 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic for Yuwathi Proxy"

# For standard HTTPS port (443)
gcloud compute firewall-rules create allow-https-443 \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic on port 443"

# List firewall rules to verify
gcloud compute firewall-rules list --filter="name~'yuwathi'"
```

### 3. Get Your GCP External IP

```bash
# Get external IP of your instance
gcloud compute instances describe your-instance-name \
    --zone=your-zone \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Or from within the instance
curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip
```

### 4. Quick GCP Deployment Script

Create a deployment script for GCP:

```bash
#!/bin/bash
# gcp-deploy.sh

echo "🚀 Deploying Yuwathi Proxy on Google Cloud Platform..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip python3-venv git openssl curl

# Clone repository (if not already done)
if [ ! -d "yuwathi-proxy" ]; then
    git clone https://github.com/yuwathi-codeblast/yuwathi-proxy.git
fi

cd yuwathi-proxy

# Setup application
chmod +x install-deps.sh setup-https.sh
./install-deps.sh

# Configure for GCP (bind to all interfaces)
echo "USE_HTTPS=true" > .env
echo "HOST=0.0.0.0" >> .env
echo "PORT=8000" >> .env
echo "DEBUG=false" >> .env

# Generate certificates and start
./setup-https.sh -i -c -s

echo "✅ Deployment complete!"
echo "🌐 Access your proxy at: https://$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip):8000/yuwathi/proxy"
```

Make it executable and run:
```bash
chmod +x gcp-deploy.sh
./gcp-deploy.sh
```

### 5. GCP-Specific Systemd Service

```bash
# Create systemd service for auto-restart
sudo tee /etc/systemd/system/yuwathi-proxy.service > /dev/null << EOF
[Unit]
Description=Yuwathi HTTPS Proxy Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=USE_HTTPS=true
Environment=HOST=0.0.0.0
Environment=PORT=8000
Environment=DEBUG=false
ExecStart=$(pwd)/env/bin/python3 $(pwd)/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable yuwathi-proxy
sudo systemctl start yuwathi-proxy

# Check status
sudo systemctl status yuwathi-proxy
```

## 🌐 External Access

### For GCP Compute Engine:

1. **Firewall is already configured** (see GCP section above)

2. **Get your external IP:**
   ```bash
   # From GCP console metadata
   curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip
   
   # Or use gcloud command
   gcloud compute instances describe $(hostname) --zone=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4) --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

3. **Test from any external client:**
   ```bash
   curl -k -X POST https://YOUR_GCP_EXTERNAL_IP:8000/yuwathi/proxy \
     -H "Content-Type: application/json" \
     -d '{"URL": "https://httpbin.org/get", "method": "GET"}'
   ```

### For other platforms:
1. **Ensure server binds to all interfaces:**
   ```bash
   export HOST=0.0.0.0  # Accept connections from any IP
   export PORT=8000     # Your chosen port
   ```

2. **Configure firewall:**
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 8000/tcp
   
   # CentOS/RHEL/Fedora  
   sudo firewall-cmd --permanent --add-port=8000/tcp
   sudo firewall-cmd --reload
   ```

For detailed external access configuration, see [LINUX-DEPLOYMENT.md](LINUX-DEPLOYMENT.md#external-access-testing).

## 📡 API Usage

### Endpoint
```
POST https://YOUR_GCP_EXTERNAL_IP:8000/yuwathi/proxy
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
# Local testing (on GCP instance)
curl -k -X POST https://localhost:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{
    "URL": "https://api.github.com/zen",
    "method": "GET"
  }'

# External access from anywhere in the world
curl -k -X POST https://YOUR_GCP_EXTERNAL_IP:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{
    "URL": "https://httpbin.org/post",
    "method": "POST",
    "data": {"message": "Hello from external client"}
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
python3 generate_ssl_cert.py
```

### Production (Let's Encrypt) - Recommended for GCP
```bash
# Install certbot
sudo apt install certbot

# Stop the proxy temporarily
sudo systemctl stop yuwathi-proxy

# Generate certificate (replace with your domain)
sudo certbot certonly --standalone -d yourdomain.com

# Update configuration
echo "SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem" >> .env
echo "SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem" >> .env

# Restart service
sudo systemctl start yuwathi-proxy

# Setup auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet --pre-hook "systemctl stop yuwathi-proxy" --post-hook "systemctl start yuwathi-proxy"
```

## 🧪 Testing

Run the test suite:
```bash
python3 test_https.py
```

## 🚀 Production Deployment

### Using Gunicorn (Recommended for GCP)
```bash
pip install gunicorn

# For production with proper certificates
gunicorn --bind 0.0.0.0:443 \
         --certfile=/etc/letsencrypt/live/yourdomain.com/fullchain.pem \
         --keyfile=/etc/letsencrypt/live/yourdomain.com/privkey.pem \
         --workers=4 \
         app:app

# For development with self-signed certificates
gunicorn --bind 0.0.0.0:8000 \
         --certfile=cert.pem \
         --keyfile=key.pem \
         --workers=2 \
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
- **Configure GCP firewall rules** appropriately for your use case
- **Monitor logs** for suspicious activity: `sudo journalctl -u yuwathi-proxy -f`
- **Consider rate limiting** for production deployments

### GCP Security Best Practices
- Use **GCP Identity and Access Management (IAM)** for access control
- Enable **GCP Security Command Center** for monitoring
- Consider using **GCP Load Balancer** with SSL termination
- Use **GCP Cloud Armor** for DDoS protection
- Enable **VPC firewall logs** for traffic analysis

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