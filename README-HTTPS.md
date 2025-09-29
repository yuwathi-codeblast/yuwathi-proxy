# Yuwathi Proxy - HTTPS Configuration

A secure HTTP(S) relay/proxy endpoint with SSL/TLS support for external traffic.

## 🚀 Quick Start (HTTPS)

### Option 1: Using PowerShell Script (Windows)

```powershell
# Install dependencies, generate certificates, and start server
.\setup-https.ps1 -InstallDeps -GenerateCert -Start
```

### Option 2: Manual Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Generate SSL certificates
python generate_ssl_cert.py

# 3. Start HTTPS server
python app.py
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
USE_HTTPS=true          # Enable HTTPS (default: true)
HOST=0.0.0.0           # Bind to all interfaces (default: 0.0.0.0)
PORT=8000              # Port number (default: 8000)
SSL_CERT_PATH=cert.pem # SSL certificate path
SSL_KEY_PATH=key.pem   # SSL private key path
DEBUG=false            # Debug mode (default: false)
```

### SSL Certificate Options

#### 1. Self-Signed Certificates (Development/Testing)

```bash
python generate_ssl_cert.py
```

This generates `cert.pem` and `key.pem` files valid for 365 days.

⚠️ **Warning**: Browsers will show security warnings for self-signed certificates.

#### 2. Let's Encrypt (Production)

For production use with a domain name:

```bash
# Install certbot
pip install certbot

# Generate certificate (replace example.com with your domain)
certbot certonly --standalone -d yourdomain.com

# Update .env file
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem
```

#### 3. Custom Certificates

If you have your own SSL certificates:

```bash
# Copy your certificates
cp your-certificate.crt cert.pem
cp your-private-key.key key.pem

# Or update .env to point to your files
SSL_CERT_PATH=/path/to/your/certificate.crt
SSL_KEY_PATH=/path/to/your/private-key.key
```

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
    "Authorization": "Bearer token",
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

## 🔒 Security Considerations

### 1. Network Security

- **Firewall**: Only open necessary ports (443 for HTTPS, 8000 for custom port)
- **IP Restrictions**: Consider restricting access to specific IP ranges
- **Rate Limiting**: Implement rate limiting for production use

### 2. SSL/TLS Best Practices

- Use strong SSL/TLS versions (TLS 1.2 minimum, prefer TLS 1.3)
- Regularly update SSL certificates
- Use certificates from trusted Certificate Authorities for production

### 3. Application Security

- **Input Validation**: The proxy validates URLs and request methods
- **Size Limits**: Configurable payload and response size limits
- **Logging**: All requests are logged for monitoring

### 4. Production Deployment

For production, consider using a proper WSGI server:

```bash
# Install gunicorn
pip install gunicorn

# Run with HTTPS
gunicorn --bind 0.0.0.0:8000 \
         --certfile=cert.pem \
         --keyfile=key.pem \
         --workers=4 \
         app:app
```

## 🧪 Testing HTTPS

### Test with curl

```bash
# Test with self-signed certificate (ignore SSL verification)
curl -k -X POST https://localhost:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{
    "URL": "https://httpbin.org/get",
    "method": "GET"
  }'

# Test with valid certificate
curl -X POST https://your-domain:8000/yuwathi/proxy \
  -H "Content-Type: application/json" \
  -d '{
    "URL": "https://httpbin.org/post",
    "method": "POST",
    "data": {"test": "data"}
  }'
```

### Test with Python

```python
import requests
import json

# Disable SSL verification for self-signed certificates
requests.packages.urllib3.disable_warnings()

url = "https://localhost:8000/yuwathi/proxy"
payload = {
    "URL": "https://httpbin.org/get",
    "method": "GET"
}

response = requests.post(url, json=payload, verify=False)
print(json.dumps(response.json(), indent=2))
```

## 🐛 Troubleshooting

### Common Issues

1. **"SSL certificate files not found"**
   - Run `python generate_ssl_cert.py` to create certificates
   - Check that `cert.pem` and `key.pem` exist in the project directory

2. **"Permission denied" on port 443**
   - Use a different port (like 8000) or run as administrator
   - Port 443 requires administrator privileges on Windows

3. **Browser security warnings**
   - Normal for self-signed certificates
   - Click "Advanced" and "Proceed" to continue (testing only)
   - Use certificates from trusted CA for production

4. **Connection refused**
   - Check if the server is running: `netstat -an | findstr :8000`
   - Verify firewall settings
   - Ensure HOST is set to `0.0.0.0` for external access

### Logs and Debugging

Enable debug mode for detailed logging:

```bash
DEBUG=true python app.py
```

## 📋 Dependencies

- **Flask**: Web framework
- **requests**: HTTP client for forwarding requests
- **cryptography**: SSL certificate generation (fallback)
- **python-dotenv**: Environment variable loading

## 🔄 Updates and Maintenance

### Certificate Renewal

Self-signed certificates expire after 365 days:

```bash
# Remove old certificates
rm cert.pem key.pem

# Generate new ones
python generate_ssl_cert.py
```

For Let's Encrypt certificates:

```bash
certbot renew
```

### Security Updates

Regularly update dependencies:

```bash
pip install --upgrade -r requirements.txt
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the application logs
3. Verify your SSL certificate configuration
4. Test with simpler HTTP requests first