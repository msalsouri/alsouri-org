#!/usr/bin/env pwsh
<#
.SYNOPSIS
    List all Partner Center customers

.DESCRIPTION
    Retrieves and displays all customers from Microsoft Partner Center.
    Optionally exports to CSV for reporting.

.PARAMETER ExportCsv
    Export results to CSV file

.EXAMPLE
    pwsh get-customers.ps1
    pwsh get-customers.ps1 -ExportCsv customers.csv
#>

param(
    [string]$ExportCsv
)

# Import module
Import-Module PartnerCenter -ErrorAction Stop

# Authenticate (assumes credentials in environment or existing session)
$appId = $env:PARTNER_CENTER_APP_ID
$secret = $env:PARTNER_CENTER_SECRET
$tenantId = $env:PARTNER_CENTER_TENANT_ID

if ($appId -and $secret -and $tenantId) {
    $secureSecret = ConvertTo-SecureString $secret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($appId, $secureSecret)
    Connect-PartnerCenter -Credential $credential -TenantId $tenantId -ServicePrincipal -ErrorAction SilentlyContinue
}

Write-Host "=== Partner Center Customers ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Retrieve customers
    Write-Host "Retrieving customers..." -ForegroundColor Yellow
    $customers = Get-PartnerCustomer
    
    if ($customers.Count -eq 0) {
        Write-Host "No customers found." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Found $($customers.Count) customers:" -ForegroundColor Green
    Write-Host ""

    # Display customer list
    $customers | Format-Table `
        @{Label="Company Name"; Expression={$_.CompanyProfile.CompanyName}}, `
        @{Label="Customer ID"; Expression={$_.Id}}, `
        @{Label="Domain"; Expression={$_.CompanyProfile.Domain}}, `
        @{Label="Relationship"; Expression={$_.RelationshipToPartner}}, `
        @{Label="Country"; Expression={$_.BillingProfile.DefaultAddress.Country}} `
        -AutoSize

    # Export if requested
    if ($ExportCsv) {
        $exportData = $customers | Select-Object `
            @{Name="CompanyName"; Expression={$_.CompanyProfile.CompanyName}}, `
            @{Name="CustomerId"; Expression={$_.Id}}, `
            @{Name="Domain"; Expression={$_.CompanyProfile.Domain}}, `
            @{Name="Email"; Expression={$_.CompanyProfile.Email}}, `
            @{Name="Relationship"; Expression={$_.RelationshipToPartner}}, `
            @{Name="Country"; Expression={$_.BillingProfile.DefaultAddress.Country}}, `
            @{Name="City"; Expression={$_.BillingProfile.DefaultAddress.City}}, `
            @{Name="State"; Expression={$_.BillingProfile.DefaultAddress.State}}, `
            @{Name="PostalCode"; Expression={$_.BillingProfile.DefaultAddress.PostalCode}}
        
        $exportData | Export-Csv -Path $ExportCsv -NoTypeInformation
        Write-Host "✅ Exported to: $ExportCsv" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Total Customers: $($customers.Count)" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Error retrieving customers: $_" -ForegroundColor Red
    exit 1
}
