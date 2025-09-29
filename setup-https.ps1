# Yuwathi Proxy HTTPS Setup Script for Windows
# This script will help you set up HTTPS for your Flask proxy

param(
    [switch]$GenerateCert,
    [switch]$InstallDeps,
    [switch]$Start,
    [string]$Port = "8000",
    [string]$Host = "0.0.0.0"
)

Write-Host "🔒 Yuwathi Proxy HTTPS Setup" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install dependencies
if ($InstallDeps) {
    Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
    
    if (Test-Path "env\Scripts\activate.ps1") {
        Write-Host "Activating virtual environment..." -ForegroundColor Green
        & "env\Scripts\Activate.ps1"
    }
    
    pip install -r requirements.txt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Generate SSL certificates
if ($GenerateCert) {
    Write-Host "🔐 Generating SSL certificates..." -ForegroundColor Yellow
    
    if (Test-Path "cert.pem") {
        $response = Read-Host "SSL certificates already exist. Overwrite? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Host "Keeping existing certificates." -ForegroundColor Yellow
        } else {
            Remove-Item "cert.pem", "key.pem" -ErrorAction SilentlyContinue
        }
    }
    
    if (-not (Test-Path "cert.pem")) {
        python generate_ssl_cert.py
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SSL certificates generated!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to generate SSL certificates" -ForegroundColor Red
            exit 1
        }
    }
}

# Start the server
if ($Start) {
    Write-Host "🚀 Starting HTTPS proxy server..." -ForegroundColor Yellow
    
    # Check if certificates exist
    if (-not (Test-Path "cert.pem") -or -not (Test-Path "key.pem")) {
        Write-Host "⚠️  SSL certificates not found. Generating them first..." -ForegroundColor Yellow
        python generate_ssl_cert.py
    }
    
    # Set environment variables
    $env:USE_HTTPS = "true"
    $env:HOST = $Host
    $env:PORT = $Port
    
    Write-Host "Server will start on: https://$Host`:$Port" -ForegroundColor Green
    Write-Host "Proxy endpoint: https://$Host`:$Port/yuwathi/proxy" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    # Activate virtual environment if it exists
    if (Test-Path "env\Scripts\activate.ps1") {
        & "env\Scripts\Activate.ps1"
    }
    
    python app.py
}

# Show help if no parameters
if (-not $GenerateCert -and -not $InstallDeps -and -not $Start) {
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\setup-https.ps1 -InstallDeps    # Install Python dependencies" -ForegroundColor Gray
    Write-Host "  .\setup-https.ps1 -GenerateCert   # Generate SSL certificates" -ForegroundColor Gray
    Write-Host "  .\setup-https.ps1 -Start          # Start HTTPS server" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Port <number>     # Port to listen on (default: 8000)" -ForegroundColor Gray
    Write-Host "  -Host <address>    # Host to bind to (default: 0.0.0.0)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\setup-https.ps1 -InstallDeps -GenerateCert -Start" -ForegroundColor Gray
    Write-Host "  .\setup-https.ps1 -Start -Port 443 -Host localhost" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Manual steps:" -ForegroundColor White
    Write-Host "1. Install dependencies: pip install -r requirements.txt" -ForegroundColor Gray
    Write-Host "2. Generate certificates: python generate_ssl_cert.py" -ForegroundColor Gray
    Write-Host "3. Start server: python app.py" -ForegroundColor Gray
}