# Linux Deployment Guide for Yuwathi Proxy

This guide covers deployment of the Yuwathi HTTPS Proxy on Linux systems.

## 🐧 Supported Linux Distributions

- **Ubuntu/Debian** (apt package manager)
- **CentOS/RHEL** (yum package manager)  
- **Fedora** (dnf package manager)
- **Arch Linux** (pacman package manager)
- **Alpine Linux** (apk package manager)

## 🚀 Quick Start (One Command)

```bash
# Clone, install dependencies, and setup everything
git clone https://github.com/yuwathi-codeblast/yuwathi-proxy.git
cd yuwathi-proxy
chmod +x install-deps.sh setup-https.sh
./install-deps.sh && ./setup-https.sh -i -c -s
```

## 📋 Step-by-Step Installation

### 1. System Prerequisites

```bash
# Make scripts executable
chmod +x install-deps.sh setup-https.sh

# Install system dependencies (automatic detection)
./install-deps.sh
```

**Manual installation by distribution:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3 python3-pip python3-venv openssl curl git

# CentOS/RHEL 8+
sudo dnf install -y python3 python3-pip openssl curl git

# CentOS/RHEL 7
sudo yum install -y python3 python3-pip openssl curl git

# Fedora
sudo dnf install -y python3 python3-pip openssl curl git

# Arch Linux
sudo pacman -S python python-pip openssl curl git

# Alpine Linux
sudo apk add python3 py3-pip openssl curl git
```

### 2. Application Setup

```bash
# Install Python dependencies and generate certificates
./setup-https.sh --install --cert

# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python generate_ssl_cert.py
```

### 3. Start the Server

```bash
# Start with the script
./setup-https.sh --start

# Or manually
source venv/bin/activate
python app.py

# Custom port and host
./setup-https.sh -s -p 443 -h 0.0.0.0
```

## � Manual Service Setup

### Create Custom Service Script

```bash
# Create a simple service wrapper script
cat > yuwathi-proxy-service.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
exec python app.py
EOF

chmod +x yuwathi-proxy-service.sh

# Test the service script
./yuwathi-proxy-service.sh
```

## ⚙️ Systemd Service Setup

### Create Service (Automatic)

```bash
# The install-deps.sh script can create this automatically
./install-deps.sh  # Answer 'y' when asked about systemd service
```

### Manual Service Creation

```bash
# Create service file
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
ExecStart=$(pwd)/venv/bin/python $(pwd)/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable yuwathi-proxy
sudo systemctl start yuwathi-proxy
```

### Service Management

```bash
# Start service
sudo systemctl start yuwathi-proxy

# Enable on boot
sudo systemctl enable yuwathi-proxy

# Check status
sudo systemctl status yuwathi-proxy

# View logs
sudo journalctl -u yuwathi-proxy -f

# Stop service
sudo systemctl stop yuwathi-proxy

# Restart service
sudo systemctl restart yuwathi-proxy
```

## 🔥 Firewall Configuration

### UFW (Ubuntu/Debian)

```bash
# Enable UFW if not enabled
sudo ufw enable

# Allow HTTPS proxy port
sudo ufw allow 8000/tcp

# Or standard HTTPS port
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

### Firewalld (CentOS/RHEL/Fedora)

```bash
# Add port to firewall
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload

# Or for standard HTTPS
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Check configuration
sudo firewall-cmd --list-all
```

### Iptables (Manual)

```bash
# Allow incoming connections on port 8000
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT

# Save rules (Ubuntu/Debian)
sudo iptables-save > /etc/iptables/rules.v4

# Save rules (CentOS/RHEL)
sudo service iptables save
```

## 🔒 Production SSL Certificates

### Let's Encrypt with Certbot

```bash
# Install Certbot
# Ubuntu/Debian:
sudo apt install certbot

# CentOS/RHEL/Fedora:
sudo dnf install certbot

# Generate certificate
sudo certbot certonly --standalone -d yourdomain.com

# Update configuration
export SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
export SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem

# Setup auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Custom Certificate Authority

```bash
# If you have your own certificates
sudo mkdir -p /etc/yuwathi-proxy/ssl
sudo cp your-certificate.crt /etc/yuwathi-proxy/ssl/cert.pem
sudo cp your-private-key.key /etc/yuwathi-proxy/ssl/key.pem
sudo chown -R $(whoami):$(whoami) /etc/yuwathi-proxy/ssl
sudo chmod 600 /etc/yuwathi-proxy/ssl/key.pem

# Update environment
export SSL_CERT_PATH=/etc/yuwathi-proxy/ssl/cert.pem
export SSL_KEY_PATH=/etc/yuwathi-proxy/ssl/key.pem
```

## 🚀 Production Deployment with Reverse Proxy

### Option 1: Direct HTTPS (Simple)

```bash
# Run on privileged port (requires root)
sudo ./setup-https.sh -s -p 443 -h 0.0.0.0

# Or use port forwarding
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8000
```

### Option 2: Nginx Reverse Proxy (Advanced)

```bash
# Install Nginx
sudo apt install nginx  # Ubuntu/Debian
sudo dnf install nginx  # CentOS/RHEL/Fedora

# Create basic reverse proxy config
sudo tee /etc/nginx/sites-available/yuwathi-proxy > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    
    location /yuwathi/proxy {
        proxy_pass https://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
    }
}
EOF

# Enable site and restart
sudo ln -s /etc/nginx/sites-available/yuwathi-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Production Checklist

- [ ] Valid SSL certificates from trusted CA
- [ ] Firewall properly configured
- [ ] Nginx reverse proxy setup
- [ ] Rate limiting enabled
- [ ] Monitoring and logging configured
- [ ] Automatic certificate renewal setup
- [ ] Backup and recovery procedures
- [ ] Security updates scheduled

## 🧪 Testing and Verification

### Test HTTPS Connectivity

```bash
# Test with curl
curl -k -X POST https://localhost:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{"URL": "https://httpbin.org/get", "method": "GET"}'

# Run test suite
./setup-https.sh test

# Or manually
source venv/bin/activate
python test_https.py
```

### Check Server Status

```bash
# Check if port is listening
ss -tuln | grep :8000

# Check process
ps aux | grep python

# Check service status
sudo systemctl status yuwathi-proxy

# Check logs
sudo journalctl -u yuwathi-proxy --since "1 hour ago"
```

### Performance Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils  # Ubuntu/Debian
sudo dnf install httpd-tools    # CentOS/RHEL/Fedora

# Test concurrent requests
ab -n 100 -c 10 -T "application/json" \
   -p test-request.json \
   https://localhost:8000/yuwathi/proxy

# Create test-request.json:
echo '{"URL": "https://httpbin.org/get", "method": "GET"}' > test-request.json
```

## 🐛 Troubleshooting

### Common Issues

**Port already in use:**
```bash
sudo netstat -tulpn | grep :8000
sudo kill $(sudo lsof -t -i:8000)
```

**Permission denied on privileged ports:**
```bash
# Use port >= 1024 or run as root
sudo ./setup-https.sh -s -p 443

# Or use port forwarding
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8000
```

**SSL certificate issues:**
```bash
# Regenerate certificates
rm -f cert.pem key.pem
./setup-https.sh -c

# Check certificate validity
openssl x509 -in cert.pem -text -noout | grep "Not After"
```

**Service won't start:**
```bash
# Check systemd logs
sudo journalctl -u yuwathi-proxy -n 50

# Check file permissions
ls -la cert.pem key.pem
chmod 644 cert.pem
chmod 600 key.pem
```

### Log Analysis

```bash
# Application logs
sudo journalctl -u yuwathi-proxy -f

# Nginx logs (if using reverse proxy)
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo tail -f /var/log/syslog  # Ubuntu/Debian
sudo tail -f /var/log/messages  # CentOS/RHEL
```

## 📊 Monitoring and Maintenance

### Log Rotation

```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/yuwathi-proxy > /dev/null << EOF
/var/log/yuwathi-proxy/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 yuwathi yuwathi
    postrotate
        systemctl reload yuwathi-proxy
    endscript
}
EOF
```

### Health Monitoring

```bash
# Create health check script
tee ~/check-yuwathi-proxy.sh > /dev/null << 'EOF'
#!/bin/bash
response=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8000/yuwathi/proxy -X POST -H "Content-Type: application/json" -d '{"URL":"https://httpbin.org/get","method":"GET"}')
if [ "$response" = "200" ]; then
    echo "$(date): Yuwathi Proxy is healthy"
else
    echo "$(date): Yuwathi Proxy health check failed (HTTP $response)"
    # Add notification logic here (email, Slack, etc.)
fi
EOF

chmod +x ~/check-yuwathi-proxy.sh

# Add to crontab for regular checks
crontab -e
# Add: */5 * * * * /home/$(whoami)/check-yuwathi-proxy.sh >> /var/log/yuwathi-proxy-health.log
```

This completes the comprehensive Linux deployment guide for the Yuwathi Proxy!