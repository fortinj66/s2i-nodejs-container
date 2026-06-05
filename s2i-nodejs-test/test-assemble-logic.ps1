#!/usr/bin/env pwsh
# Test the assemble script version parsing logic without building containers

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$TestResults = @()

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error-Custom { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning-Custom { param($msg) Write-Host $msg -ForegroundColor Yellow }

# Test case data
$testCases = @(
    @{
        Name = "exact-version"
        PackageJson = '{"engines":{"node":"14.17.0"}}'
        ExpectedVersion = "14.17.0"
        Description = "Exact version 14.17.0"
    },
    @{
        Name = "caret-version"
        PackageJson = '{"engines":{"node":"^14.0.0"}}'
        ExpectedVersion = "14.0.0"
        Description = "Caret range ^14.0.0"
    },
    @{
        Name = "tilde-version"
        PackageJson = '{"engines":{"node":"~16.13.0"}}'
        ExpectedVersion = "16.13.0"
        Description = "Tilde range ~16.13.0"
    },
    @{
        Name = "range-version"
        PackageJson = '{"engines":{"node":">=14.0.0 <17.0.0"}}'
        ExpectedVersion = "14.0.0"
        Description = "Range >=14.0.0 <17.0.0 (should extract first match)"
    },
    @{
        Name = "no-engines"
        PackageJson = '{"name":"test"}'
        ExpectedVersion = $null
        Description = "No engines field (should return null)"
    },
    @{
        Name = "no-package-json"
        PackageJson = $null
        ExpectedVersion = $null
        Description = "Missing package.json (should handle gracefully)"
    }
)

# Current broken implementation (from assemble script)
function Test-CurrentImplementation {
    param([string]$PackageJsonContent)
    
    if (!$PackageJsonContent) {
        return $null
    }
    
    Set-Content -Path ".\test-package.json" -Value $PackageJsonContent
    
    try {
        $result = node -e "console.log(require('./test-package.json').engines.node);" 2>$null
        
        # Current broken sed commands (translated to PowerShell)
        $result = $result -replace '[\^~]', ''
        $result = $result -replace '.\d', ''  # This is the buggy line
        $result = $result -replace 'undefined', ''
        
        Remove-Item ".\test-package.json" -Force
        return $result.Trim()
    } catch {
        Remove-Item ".\test-package.json" -Force -ErrorAction SilentlyContinue
        return $null
    }
}

# Fixed implementation
function Test-FixedImplementation {
    param([string]$PackageJsonContent)
    
    if (!$PackageJsonContent) {
        return $null
    }
    
    Set-Content -Path ".\test-package.json" -Value $PackageJsonContent
    
    try {
        $result = node -e @"
const pkg = require('./test-package.json');
const spec = pkg.engines?.node || '';
const match = spec.match(/(\d+)\.(\d+)\.?(\d*)/);
if (match) {
    console.log(match[1] + '.' + match[2] + (match[3] ? '.' + match[3] : ''));
}
"@ 2>$null
        
        Remove-Item ".\test-package.json" -Force
        return $result.Trim()
    } catch {
        Remove-Item ".\test-package.json" -Force -ErrorAction SilentlyContinue
        return $null
    }
}

Write-Info "Testing Node.js Version Parsing Logic"
Write-Host ""

foreach ($test in $testCases) {
    Write-Host ("-" * 60)
    Write-Info "Test: $($test.Name)"
    Write-Host "  Description: $($test.Description)"
    Write-Host "  Expected: $(if ($test.ExpectedVersion) { $test.ExpectedVersion } else { 'null' })"
    
    # Test current implementation
    $currentResult = Test-CurrentImplementation -PackageJsonContent $test.PackageJson
    Write-Host "  Current: '$currentResult'"
    
    # Test fixed implementation
    $fixedResult = Test-FixedImplementation -PackageJsonContent $test.PackageJson
    Write-Host "  Fixed:   '$fixedResult'"
    
    # Evaluate
    $currentPass = ($currentResult -eq $test.ExpectedVersion)
    $fixedPass = ($fixedResult -eq $test.ExpectedVersion)
    
    if ($currentPass) {
        Write-Success "  Current: PASS"
    } else {
        Write-Error-Custom "  Current: FAIL"
    }
    
    if ($fixedPass) {
        Write-Success "  Fixed:   PASS"
    } else {
        Write-Error-Custom "  Fixed:   FAIL"
    }
    
    $TestResults += @{
        Name = $test.Name
        Expected = $test.ExpectedVersion
        Current = $currentResult
        Fixed = $fixedResult
        CurrentPass = $currentPass
        FixedPass = $fixedPass
    }
    
    Write-Host ""
}

# Summary
Write-Host ("=" * 60)
Write-Info "Summary"
Write-Host ""

$currentPassCount = ($TestResults | Where-Object { $_.CurrentPass }).Count
$fixedPassCount = ($TestResults | Where-Object { $_.FixedPass }).Count

Write-Host "Current Implementation: $currentPassCount/$($TestResults.Count) passed"
Write-Host "Fixed Implementation:   $fixedPassCount/$($TestResults.Count) passed"
Write-Host ""

if ($fixedPassCount -gt $currentPassCount) {
    Write-Success "Fixed implementation shows improvement!"
} elseif ($fixedPassCount -eq $currentPassCount) {
    Write-Warning-Custom "No difference detected - check test cases"
} else {
    Write-Error-Custom "Fixed implementation performed worse - review logic"
}

# Detailed results
$TestResults | Format-Table -AutoSize Name, Expected, Current, Fixed, CurrentPass, FixedPass

# Cleanup
Remove-Item ".\test-package.json" -ErrorAction SilentlyContinue
