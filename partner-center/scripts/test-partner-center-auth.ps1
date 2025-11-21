#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Microsoft Partner Center authentication

.DESCRIPTION
    Validates Partner Center API connectivity using app credentials.
    Tests both service principal and user authentication methods.

.EXAMPLE
    pwsh test-partner-center-auth.ps1
#>

param(
    [switch]$UseDeviceAuth
)

# Import required module
Import-Module PartnerCenter -ErrorAction Stop

Write-Host "=== Partner Center Authentication Test ===" -ForegroundColor Cyan
Write-Host ""

# Check for environment variables
$appId = $env:PARTNER_CENTER_APP_ID
$secret = $env:PARTNER_CENTER_SECRET
$tenantId = $env:PARTNER_CENTER_TENANT_ID

if ($UseDeviceAuth) {
    Write-Host "Using device authentication (interactive)..." -ForegroundColor Yellow
    try {
        Connect-PartnerCenter -UseDeviceAuthentication
        Write-Host "✅ Successfully authenticated to Partner Center!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Authentication failed: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    # Validate environment variables
    if (-not $appId -or -not $secret -or -not $tenantId) {
        Write-Host "❌ Missing environment variables!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please set the following environment variables:" -ForegroundColor Yellow
        Write-Host "  - PARTNER_CENTER_APP_ID" -ForegroundColor Yellow
        Write-Host "  - PARTNER_CENTER_SECRET" -ForegroundColor Yellow
        Write-Host "  - PARTNER_CENTER_TENANT_ID" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or run with -UseDeviceAuth flag for interactive authentication" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "App ID: $appId" -ForegroundColor Gray
    Write-Host "Tenant ID: $tenantId" -ForegroundColor Gray
    Write-Host ""

    # Create credential
    $secureSecret = ConvertTo-SecureString $secret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($appId, $secureSecret)

    # Attempt connection
    Write-Host "Connecting to Partner Center..." -ForegroundColor Yellow
    try {
        Connect-PartnerCenter -Credential $credential -TenantId $tenantId -ServicePrincipal -ErrorAction Stop
        Write-Host "✅ Successfully authenticated to Partner Center!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Authentication failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "  1. App registration not created" -ForegroundColor Yellow
        Write-Host "  2. Client secret expired or incorrect" -ForegroundColor Yellow
        Write-Host "  3. Missing Partner Center API permissions" -ForegroundColor Yellow
        Write-Host "  4. Admin consent not granted" -ForegroundColor Yellow
        exit 1
    }
}

# Test basic API call
Write-Host ""
Write-Host "Testing API access..." -ForegroundColor Yellow
try {
    $context = Get-PartnerContext
    Write-Host "✅ Partner Center context retrieved!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Account Details:" -ForegroundColor Cyan
    Write-Host "  Account ID: $($context.AccountId)" -ForegroundColor Gray
    Write-Host "  Environment: $($context.Environment)" -ForegroundColor Gray
    
    # Try to get organization profile
    Write-Host ""
    Write-Host "Retrieving organization profile..." -ForegroundColor Yellow
    $profile = Get-PartnerOrganizationProfile -ErrorAction Stop
    Write-Host "✅ Organization profile retrieved!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Organization Details:" -ForegroundColor Cyan
    Write-Host "  Company Name: $($profile.CompanyName)" -ForegroundColor Gray
    Write-Host "  Country: $($profile.DefaultAddress.Country)" -ForegroundColor Gray
    Write-Host "  MPN ID: $($profile.MpnId)" -ForegroundColor Gray
}
catch {
    Write-Host "⚠️  API call failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Authentication succeeded but API access failed." -ForegroundColor Yellow
    Write-Host "Check Partner Center permissions and account setup." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== All tests passed! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Explore available cmdlets: Get-Command -Module PartnerCenter" -ForegroundColor Gray
Write-Host "  2. List customers: Get-PartnerCustomer" -ForegroundColor Gray
Write-Host "  3. View invoices: Get-PartnerInvoice" -ForegroundColor Gray
Write-Host "  4. Check subscriptions: Get-PartnerCustomerSubscription" -ForegroundColor Gray
