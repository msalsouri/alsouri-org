#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Get Partner Center usage analytics

.DESCRIPTION
    Retrieves Azure usage analytics for all customers or a specific customer.
    Useful for tracking consumption and identifying growth opportunities.

.PARAMETER CustomerId
    Specific customer ID to analyze (optional)

.PARAMETER Days
    Number of days to analyze (default: 30)

.EXAMPLE
    pwsh get-usage-analytics.ps1
    pwsh get-usage-analytics.ps1 -CustomerId <customer-id> -Days 90
#>

param(
    [string]$CustomerId,
    [int]$Days = 30
)

Import-Module PartnerCenter -ErrorAction Stop

# Authenticate
$appId = $env:PARTNER_CENTER_APP_ID
$secret = $env:PARTNER_CENTER_SECRET
$tenantId = $env:PARTNER_CENTER_TENANT_ID

if ($appId -and $secret -and $tenantId) {
    $secureSecret = ConvertTo-SecureString $secret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($appId, $secureSecret)
    Connect-PartnerCenter -Credential $credential -TenantId $tenantId -ServicePrincipal -ErrorAction SilentlyContinue
}

Write-Host "=== Partner Center Usage Analytics ===" -ForegroundColor Cyan
Write-Host "Period: Last $Days days" -ForegroundColor Gray
Write-Host ""

try {
    if ($CustomerId) {
        # Single customer analysis
        Write-Host "Analyzing customer: $CustomerId" -ForegroundColor Yellow
        $customer = Get-PartnerCustomer -CustomerId $CustomerId
        Write-Host "Company: $($customer.CompanyProfile.CompanyName)" -ForegroundColor Cyan
        Write-Host ""

        # Get subscriptions
        $subscriptions = Get-PartnerCustomerSubscription -CustomerId $CustomerId
        Write-Host "Active Subscriptions: $($subscriptions.Count)" -ForegroundColor Green
        
        # Get Azure usage
        $endDate = Get-Date
        $startDate = $endDate.AddDays(-$Days)
        
        Write-Host ""
        Write-Host "Retrieving Azure usage data..." -ForegroundColor Yellow
        $usage = Get-PartnerCustomerUsage -CustomerId $CustomerId -StartDate $startDate -EndDate $endDate
        
        if ($usage) {
            Write-Host "✅ Usage data retrieved" -ForegroundColor Green
            $usage | Format-Table -AutoSize
        }
        else {
            Write-Host "No usage data found for this period" -ForegroundColor Yellow
        }
    }
    else {
        # All customers overview
        Write-Host "Retrieving all customers..." -ForegroundColor Yellow
        $customers = Get-PartnerCustomer
        
        Write-Host "Found $($customers.Count) customers" -ForegroundColor Green
        Write-Host ""

        $summary = @()
        foreach ($cust in $customers) {
            Write-Host "Processing: $($cust.CompanyProfile.CompanyName)..." -ForegroundColor Gray
            
            $subscriptions = Get-PartnerCustomerSubscription -CustomerId $cust.Id
            $azureSubscriptions = $subscriptions | Where-Object { $_.OfferName -like "*Azure*" }
            
            $summary += [PSCustomObject]@{
                CompanyName = $cust.CompanyProfile.CompanyName
                CustomerId = $cust.Id
                TotalSubscriptions = $subscriptions.Count
                AzureSubscriptions = $azureSubscriptions.Count
                Domain = $cust.CompanyProfile.Domain
                Country = $cust.BillingProfile.DefaultAddress.Country
            }
        }

        Write-Host ""
        Write-Host "=== Customer Summary ===" -ForegroundColor Cyan
        $summary | Format-Table -AutoSize

        # Statistics
        $totalSubs = ($summary | Measure-Object -Property TotalSubscriptions -Sum).Sum
        $totalAzure = ($summary | Measure-Object -Property AzureSubscriptions -Sum).Sum
        
        Write-Host ""
        Write-Host "=== Statistics ===" -ForegroundColor Cyan
        Write-Host "Total Customers: $($customers.Count)" -ForegroundColor Green
        Write-Host "Total Subscriptions: $totalSubs" -ForegroundColor Green
        Write-Host "Azure Subscriptions: $totalAzure" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
