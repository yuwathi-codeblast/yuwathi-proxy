#!/usr/bin/env python3
"""
Generate self-signed SSL certificates for the proxy server.
This is suitable for development and testing purposes only.
"""
import os
import subprocess
import sys
from datetime import datetime, timedelta

def generate_self_signed_cert():
    """Generate self-signed SSL certificate using OpenSSL."""
    cert_file = "cert.pem"
    key_file = "key.pem"
    
    # Check if certificates already exist
    if os.path.exists(cert_file) and os.path.exists(key_file):
        print(f"SSL certificates already exist: {cert_file}, {key_file}")
        return True
    
    try:
        # Generate self-signed certificate
        cmd = [
            "openssl", "req", "-x509", "-newkey", "rsa:4096", 
            "-keyout", key_file, "-out", cert_file, 
            "-days", "365", "-nodes", "-batch",
            "-subj", "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        ]
        
        print("Generating self-signed SSL certificate...")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ SSL certificate generated successfully!")
            print(f"   Certificate: {cert_file}")
            print(f"   Private Key: {key_file}")
            print(f"   Valid for: 365 days from today")
            print()
            print("⚠️  WARNING: This is a self-signed certificate!")
            print("   Browsers will show security warnings.")
            print("   For production, use certificates from a trusted CA.")
            return True
        else:
            print(f"❌ Failed to generate certificate: {result.stderr}")
            return False
            
    except FileNotFoundError:
        print("❌ OpenSSL not found. Please install OpenSSL:")
        print("   Windows: Download from https://slproweb.com/products/Win32OpenSSL.html")
        print("   Or use: winget install OpenSSL.OpenSSL")
        return False
    except Exception as e:
        print(f"❌ Error generating certificate: {e}")
        return False

def generate_cert_with_python():
    """Generate certificate using Python cryptography library as fallback."""
    try:
        from cryptography import x509
        from cryptography.x509.oid import NameOID
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import rsa
        import ipaddress
        
        print("Generating SSL certificate using Python cryptography library...")
        
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=4096,
        )
        
        # Create certificate
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "State"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "City"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Yuwathi Proxy"),
            x509.NameAttribute(NameOID.COMMON_NAME, "localhost"),
        ])
        
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.utcnow()
        ).not_valid_after(
            datetime.utcnow() + timedelta(days=365)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("localhost"),
                x509.DNSName("127.0.0.1"),
                x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
                x509.IPAddress(ipaddress.IPv6Address("::1")),
            ]),
            critical=False,
        ).sign(private_key, hashes.SHA256())
        
        # Write certificate
        with open("cert.pem", "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        
        # Write private key
        with open("key.pem", "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        print("✅ SSL certificate generated successfully using Python!")
        print("   Certificate: cert.pem")
        print("   Private Key: key.pem")
        return True
        
    except ImportError:
        print("❌ cryptography library not found. Install it with:")
        print("   pip install cryptography")
        return False
    except Exception as e:
        print(f"❌ Error generating certificate with Python: {e}")
        return False

if __name__ == "__main__":
    print("🔒 SSL Certificate Generator for Yuwathi Proxy")
    print("=" * 50)
    
    # Try OpenSSL first, then Python cryptography as fallback
    if not generate_self_signed_cert():
        print()
        print("Trying alternative method with Python cryptography...")
        if not generate_cert_with_python():
            print()
            print("❌ Unable to generate SSL certificates.")
            print("Please install either OpenSSL or the cryptography Python package.")
            sys.exit(1)
    
    print()
    print("🚀 You can now start the HTTPS proxy server:")
    print("   python app.py")
    print()
    print("📝 Environment variables you can set:")
    print("   USE_HTTPS=true    (enable HTTPS, default: true)")
    print("   HOST=0.0.0.0      (bind address, default: 0.0.0.0)")
    print("   PORT=8000         (port number, default: 8000)")
    print("   SSL_CERT_PATH=cert.pem  (certificate path)")
    print("   SSL_KEY_PATH=key.pem    (private key path)")