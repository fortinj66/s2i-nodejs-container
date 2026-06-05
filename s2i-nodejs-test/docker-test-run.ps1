#!/usr/bin/env pwsh
# Simple Docker-based test without needing s2i or make

param(
    [switch]$BuildBase,
    [string]$TestName = "node-14-exact"
)

$ErrorActionPreference = "Continue"

function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error-Custom { param($msg) Write-Host $msg -ForegroundColor Red }

# Use existing Node.js image as base instead of building from scratch
$baseImages = @{
    "14" = "node:14"
    "16" = "node:16"
    "18" = "node:18"
    "20" = "node:20"
}

Write-Info "Testing Node.js version override with Docker"
Write-Host ""

# Test 1: Base image version
Write-Info "Test 1: Check base Node:14 image version"
$version = docker run --rm node:14 node --version 2>&1
Write-Host "  Base node:14 version: $version"
Write-Host ""

# Test 2: Simulate version override with nvm install
Write-Info "Test 2: Simulate assemble script with nvm install (Node 18)"
$testScript = @"
FROM node:14
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash
RUN export NVM_DIR=`"`$HOME/.nvm`" && [ -s `"`$NVM_DIR/nvm.sh`" ] && . `"`$NVM_DIR/nvm.sh`" && nvm install 18.0.0 && nvm use 18.0.0
CMD ["node", "--version"]
"@

$testScript | Set-Content -Path ".\Dockerfile.test" -Encoding UTF8
docker build -t test-nvm-version -f .\Dockerfile.test . 2>&1 | Select-String -Pattern "installed|npm"

Write-Info "Running container..."
$overriddenVersion = docker run --rm test-nvm-version 2>&1
Write-Host "  Version after nvm install: $overriddenVersion"
Write-Host ""

# Test 3: Test with our fixed parsing logic
Write-Info "Test 3: Test version parsing logic"
cd ..\s2i-nodejs-test
.\test-assemble-logic.ps1

# Cleanup
Remove-Item ".\Dockerfile.test" -Force -ErrorAction SilentlyContinue
docker rmi test-nvm-version --force -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Success "Tests complete!"
