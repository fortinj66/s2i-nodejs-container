#!/usr/bin/env pwsh
# S2I Node.js Version Override Test Runner

param(
    [string]$TestName = "",
    [switch]$Verbose,
    [switch]$Cleanup,
    [string]$BaseImage = "quay.io/centos7/nodejs-14-centos7:latest"
)

$ErrorActionPreference = "Stop"
$TestResults = @()
$TestAppsDir = Join-Path $PSScriptRoot "test-apps"

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error-Custom { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning-Custom { param($msg) Write-Host $msg -ForegroundColor Yellow }

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    $missing = @()
    
    if (!(Get-Command podman -ErrorAction SilentlyContinue) -and 
        !(Get-Command docker -ErrorAction SilentlyContinue)) {
        $missing += "podman or docker"
    }
    
    if (!(Get-Command s2i -ErrorAction SilentlyContinue)) {
        Write-Warning-Custom "s2i CLI not found. Will use docker build instead."
        Write-Info "Install s2i with: choco install s2i -y"
    }
    
    if ($missing.Count -gt 0) {
        Write-Error-Custom "Missing prerequisites: $($missing -join ', ')"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Build-TestImage {
    param(
        [string]$TestApp,
        [string]$ImageName,
        [hashtable]$Environment = @{}
    )
    
    $testPath = Join-Path $TestAppsDir $TestApp
    Write-Info "Building $ImageName from $TestApp..."
    
    if (Get-Command s2i -ErrorAction SilentlyContinue) {
        $buildArgs = @(
            "build", $testPath, $BaseImage, $ImageName
            "--pull-policy", "if-not-present"
            "--scripts-url", "image:///usr/libexec/s2i"
        )
        
        foreach ($key in $Environment.Keys) {
            $buildArgs += "--environment", "$key=$($Environment[$key])"
        }
        
        & s2i $buildArgs 2>&1 | ForEach-Object {
            if ($Verbose) { Write-Host $_ }
        }
    } else {
        Write-Warning-Custom "Using docker build (S2I not available)"
        
        $dockerfileContent = "FROM $BaseImage`nCOPY . /tmp/src/`nUSER root`nRUN chown -R 1001:0 /opt/app-root/src`nUSER 1001`n"
        $dockerfilePath = Join-Path $testPath "Dockerfile.test"
        Set-Content -Path $dockerfilePath -Value $dockerfileContent
        
        & docker build "-t" $ImageName "-f" $dockerfilePath $testPath 2>&1 | ForEach-Object {
            if ($Verbose) { Write-Host $_ }
        }
        
        Remove-Item $dockerfilePath -Force
    }
}

function Invoke-VersionTest {
    param(
        [string]$TestName,
        [string]$ImageName,
        [string]$ExpectedVersion,
        [string]$Description
    )
    
    Write-Info "Testing: $TestName"
    Write-Host "  Description: $Description"
    Write-Host "  Expected: $ExpectedVersion"
    
    try {
        $containerCmd = if (Get-Command podman -ErrorAction SilentlyContinue) { "podman" } else { "docker" }
        
        $versionOutput = & $containerCmd run --rm $ImageName node --version 2>&1
        $actualVersion = $versionOutput.TrimStart('v')
        
        Write-Host "  Actual: $actualVersion"
        
        if ($ExpectedVersion -eq "any" -or $actualVersion -match "^$($ExpectedVersion.Replace('.', '\.'))") {
            Write-Success "  PASS"
            return @{
                TestName = $TestName
                Status = "PASS"
                Expected = $ExpectedVersion
                Actual = $actualVersion
                Notes = ""
            }
        } else {
            Write-Error-Custom "  FAIL: Version mismatch"
            return @{
                TestName = $TestName
                Status = "FAIL"
                Expected = $ExpectedVersion
                Actual = $actualVersion
                Notes = "Version mismatch"
            }
        }
    } catch {
        Write-Error-Custom "  FAIL: $($_.Exception.Message)"
        return @{
            TestName = $TestName
            Status = "ERROR"
            Expected = $ExpectedVersion
            Actual = "N/A"
            Notes = $_.Exception.Message
        }
    }
}

function Remove-TestImages {
    Write-Info "Cleaning up test images..."
    
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        podman images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -like "s2i-test-*" } | ForEach-Object {
            Write-Host "  Removing $_"
            podman rmi $_ --force 2>$null
        }
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -like "s2i-test-*" } | ForEach-Object {
            Write-Host "  Removing $_"
            docker rmi $_ --force 2>$null
        }
    }
}

function Invoke-TestSuite {
    Write-Info "Starting S2I Node.js Version Override Test Suite"
    Write-Host "Base Image: $BaseImage"
    Write-Host ""
    
    Test-Prerequisites
    
    $testCases = @(
        @{
            TestName = "node-14-exact"
            ImageName = "s2i-test-node-14-exact"
            ExpectedVersion = "14.17.0"
            Description = "Exact version from package.json engines"
            Environment = @{}
        },
        @{
            TestName = "node-14-caret"
            ImageName = "s2i-test-node-14-caret"
            ExpectedVersion = "14\."
            Description = "Caret range ^14.0.0 from package.json"
            Environment = @{}
        },
        @{
            TestName = "node-16-exact"
            ImageName = "s2i-test-node-16-exact"
            ExpectedVersion = "16.13.0"
            Description = "Exact version 16.13.0 from package.json"
            Environment = @{}
        },
        @{
            TestName = "node-env-override"
            ImageName = "s2i-test-node-env-override"
            ExpectedVersion = "18.0.0"
            Description = "NODE_VERSION environment variable override"
            Environment = @{ NODE_VERSION = "18.0.0" }
        },
        @{
            TestName = "node-nvmrc"
            ImageName = "s2i-test-node-nvmrc"
            ExpectedVersion = "20.0.0"
            Description = ".nvmrc file version"
            Environment = @{}
        }
    )
    
    if ($TestName) {
        $testCases = $testCases | Where-Object { $_.TestName -eq $TestName }
        if ($testCases.Count -eq 0) {
            Write-Error-Custom "Test '$TestName' not found"
            exit 1
        }
    }
    
    foreach ($test in $testCases) {
        Write-Host ""
        Write-Host ("=" * 60)
        
        Build-TestImage -TestApp $test.TestName -ImageName $test.ImageName -Environment $test.Environment
        
        $result = Invoke-VersionTest `
            -TestName $test.TestName `
            -ImageName $test.ImageName `
            -ExpectedVersion $test.ExpectedVersion `
            -Description $test.Description
        
        $TestResults += $result
        
        if ($Cleanup) {
            Remove-TestImages
        }
    }
    
    Write-Host ""
    Write-Host ("=" * 60)
    Write-Info "Test Summary"
    Write-Host ""
    
    $passCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $errorCount = ($TestResults | Where-Object { $_.Status -eq "ERROR" }).Count
    
    Write-Host "Total: $($TestResults.Count) | Pass: $passCount | Fail: $failCount | Error: $errorCount"
    Write-Host ""
    
    $TestResults | Format-Table -AutoSize TestName, Status, Expected, Actual, Notes
    
    if ($failCount -gt 0 -or $errorCount -gt 0) {
        exit 1
    }
}

Invoke-TestSuite
