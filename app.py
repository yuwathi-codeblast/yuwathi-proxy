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
from urllib.parse import urlparse

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

if __name__ == "__main__":
    # WARNING: Do not run this unprotected on a public IP.
    app.run(host="127.0.0.1", port=8000, debug=False)
