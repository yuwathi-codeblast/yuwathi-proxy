# Security Guidelines for Yuwathi Proxy

## 🔒 Files That Should NEVER Be Committed

### SSL Certificates and Private Keys
- `cert.pem` - SSL certificate
- `key.pem` - Private key (⚠️ **CRITICAL: Never commit this!**)
- `*.p12`, `*.pfx` - Certificate bundles
- `*.jks` - Java keystores

### Environment Configuration
- `.env` - May contain sensitive configuration
- `config.local.py` - Local configuration files
- Any files with passwords, API keys, or secrets

### Virtual Environment
- `env/` - Python virtual environment
- `venv/` - Alternative virtual environment name
- `__pycache__/` - Python bytecode cache

## ✅ Files Safe to Commit

### Configuration Templates
- `.env.example` - Template showing required variables (no actual values)
- `requirements.txt` - Python package dependencies
- Configuration documentation and examples

### Application Code
- `app.py` - Main application (without hardcoded secrets)
- `generate_ssl_cert.py` - Certificate generation utility
- `test_*.py` - Test scripts
- `setup-*.ps1` - Setup automation scripts

### Documentation
- `README.md` - Project documentation
- `*.md` - Documentation files
- License files

## 🛡️ Security Best Practices

### Before Committing
1. **Review changes**: Always check `git diff` before committing
2. **Check git status**: Ensure no sensitive files are staged
3. **Use .gitignore**: Maintain comprehensive ignore rules
4. **Environment variables**: Use env vars for secrets, never hardcode

### Production Deployment
1. **Use proper certificates**: Get certificates from trusted CAs
2. **Secure configuration**: Store secrets in secure vaults or environment variables
3. **Access controls**: Implement proper authentication and authorization
4. **Monitoring**: Log and monitor all access appropriately

### Development
1. **Self-signed certificates**: Fine for development, but warn users about security
2. **Local configuration**: Keep local settings separate from repository
3. **Test data**: Don't use real credentials in tests

## 📋 Pre-Commit Checklist

- [ ] No SSL private keys (*.key, *.pem with private data)
- [ ] No .env files with real values
- [ ] No hardcoded passwords or API keys
- [ ] No production certificates
- [ ] Virtual environment excluded
- [ ] Cache files excluded
- [ ] Local configuration files excluded

## 🚨 If You Accidentally Commit Secrets

If you accidentally commit sensitive data:

1. **Immediately rotate** any exposed credentials
2. **Remove from history**: Use `git filter-branch` or BFG Repo-Cleaner
3. **Force push**: Update the repository to remove the sensitive data
4. **Notify team**: If this is a shared repository

### Remove from Git History
```bash
# Remove a specific file from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch cert.pem' \
  --prune-empty --tag-name-filter cat -- --all

# Force push to update remote
git push origin --force --all
```

## 📝 Environment Variable Guidelines

### For .env.example (safe to commit):
```bash
# HTTPS Configuration
USE_HTTPS=true
HOST=0.0.0.0
PORT=8000

# SSL Certificate paths (update for your setup)
SSL_CERT_PATH=cert.pem
SSL_KEY_PATH=key.pem

# Debug mode (false for production)
DEBUG=false
```

### For .env (NEVER commit):
```bash
# Actual configuration with real paths and settings
USE_HTTPS=true
HOST=0.0.0.0
PORT=8000
SSL_CERT_PATH=/etc/ssl/certs/yuwathi.crt
SSL_KEY_PATH=/etc/ssl/private/yuwathi.key
DEBUG=false
```

Remember: **When in doubt, don't commit it!** It's easier to add files later than to remove sensitive data from Git history.