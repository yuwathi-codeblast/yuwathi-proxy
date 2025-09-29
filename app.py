#!/usr/bin/env python3
"""
Simple HTTP(S) relay/proxy endpoint.

POST JSON to /proxy with:
{
  "URL": "https://example.com/api",
  "method": "POST",
  "header": {"Accept": "application/json", "X-Api-Key": "xxx"},
  "data": {"foo": "bar"}         # or string for raw body
  "timeout": 10,                 # optional seconds
  "verify": true,                # optional, default true (SSL verification)
  "allow_redirects": true        # optional
}

Response will be JSON:
{
  "status_code": 200,
  "headers": {...},
  "is_base64": false,
  "body": "..." or base64 string,
  "error": null
}
"""
from flask import Flask, request, jsonify, abort
import requests
import base64
import json
import logging
import ssl
import os
from urllib.parse import urlparse

# Load environment variables from .env file if it exists
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv not installed

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Controls / limits
ALLOWED_METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
MAX_INCOMING_PAYLOAD_BYTES = 2 * 1024 * 1024       # 2 MB from client to this proxy
MAX_RESPONSE_BYTES = 5 * 1024 * 1024               # 5 MB to return in body

def is_valid_target_url(url: str) -> bool:
    try:
        p = urlparse(url)
        return p.scheme in ("http", "https") and bool(p.netloc)
    except Exception:
        return False

@app.route("/yuwathi/proxy", methods=["POST"])
def proxy():
    # Basic content-length guard
    cl = request.content_length
    if cl is not None and cl > MAX_INCOMING_PAYLOAD_BYTES:
        abort(413, description="Payload too large")

    if not request.is_json:
        return jsonify({"error": "expected application/json"}), 400

    payload = request.get_json()

    # Required fields
    target = payload.get("URL") or payload.get("url")
    method = (payload.get("method") or "GET").upper()
    headers = payload.get("header") or payload.get("headers") or {}
    data = payload.get("data", None)

    # Optional
    timeout = float(payload.get("timeout", 10))
    verify = payload.get("verify", True)
    allow_redirects = bool(payload.get("allow_redirects", True))

    # Basic validation
    if not target or not isinstance(target, str) or not is_valid_target_url(target):
        return jsonify({"error": "invalid or missing URL"}), 400

    if method not in ALLOWED_METHODS:
        return jsonify({"error": f"method not allowed. allowed: {sorted(ALLOWED_METHODS)}"}), 405

    # headers should be a mapping
    if not isinstance(headers, dict):
        return jsonify({"error": "header must be a JSON object/dict"}), 400

    # Prepare request kwargs
    req_kwargs = {
        "headers": headers,
        "timeout": timeout,
        "verify": verify,
        "allow_redirects": allow_redirects,
    }

    # If data is a JSON-serializable object and client didn't set Content-Type, send as JSON
    if data is not None:
        # If client provided raw string, send as-is
        if isinstance(data, (str, bytes)):
            req_kwargs["data"] = data
        else:
            # send as json
            req_kwargs["json"] = data

    try:
        logging.info("Forwarding %s %s", method, target)
        resp = requests.request(method, target, **req_kwargs)
    except requests.RequestException as e:
        logging.exception("Request to target failed")
        return jsonify({"error": "request_failed", "details": str(e)}), 502

    # Limit how much body we return
    content = resp.content
    if len(content) > MAX_RESPONSE_BYTES:
        # return partial + a flag that it was truncated
        truncated = True
        content_to_return = content[:MAX_RESPONSE_BYTES]
    else:
        truncated = False
        content_to_return = content

    # Try to decode as utf-8 text; if not, base64 encode
    try:
        body_text = content_to_return.decode("utf-8")
        is_base64 = False
        body_field = body_text
    except Exception:
        is_base64 = True
        body_field = base64.b64encode(content_to_return).decode("ascii")

    # Build response headers (strip hop-by-hop headers)
    hop_by_hop = {
        "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
        "te", "trailers", "transfer-encoding", "upgrade"
    }
    response_headers = {k: v for k, v in resp.headers.items() if k.lower() not in hop_by_hop}

    out = {
        "status_code": resp.status_code,
        "headers": response_headers,
        "is_base64": is_base64,
        "body": body_field,
        "truncated": truncated,
        "reason": resp.reason,
    }

    return jsonify(out), 200

def create_ssl_context():
    """Create SSL context for HTTPS support."""
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    
    # Try to load SSL certificates from environment variables or default paths
    cert_file = os.getenv('SSL_CERT_PATH', 'cert.pem')
    key_file = os.getenv('SSL_KEY_PATH', 'key.pem')
    
    if os.path.exists(cert_file) and os.path.exists(key_file):
        try:
            context.load_cert_chain(cert_file, key_file)
            logging.info(f"SSL certificates loaded from {cert_file} and {key_file}")
            return context
        except Exception as e:
            logging.error(f"Failed to load SSL certificates: {e}")
            return None
    else:
        logging.warning("SSL certificate files not found. Please create SSL certificates.")
        logging.info("To create self-signed certificates, run:")
        logging.info("openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        return None

if __name__ == "__main__":
    # Configuration from environment variables
    host = os.getenv('HOST', '0.0.0.0')  # Changed to accept external connections
    port = int(os.getenv('PORT', '8000'))
    use_https = os.getenv('USE_HTTPS', 'true').lower() == 'true'
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    if use_https:
        ssl_context = create_ssl_context()
        if ssl_context:
            logging.info(f"Starting HTTPS server on {host}:{port}")
            app.run(host=host, port=port, debug=debug, ssl_context=ssl_context)
        else:
            logging.error("Cannot start HTTPS server without valid SSL certificates.")
            logging.info("Falling back to HTTP server.")
            app.run(host=host, port=port, debug=debug)
    else:
        logging.info(f"Starting HTTP server on {host}:{port}")
        app.run(host=host, port=port, debug=debug)
