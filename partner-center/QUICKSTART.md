# Partner Center Integration - Quick Start Guide

## ✅ Current Status

You already have all required tools installed:
- ✅ PowerShell Core (pwsh)
- ✅ PartnerCenter module v3.0.10
- ✅ Az PowerShell modules v14.1.0
- ✅ Azure CLI (authenticated)

## 🚀 Setup Steps

### Step 1: Create App Registration

Run this command to create an Azure AD app for Partner Center:

```bash
az ad app create \
  --display-name "ALSOURI Partner Center Integration" \
  --sign-in-audience AzureADMyOrg
```

**Save the output!** You'll need the `appId` (Client ID) from the response.

### Step 2: Create Client Secret

Replace `<APP_ID>` with the appId from Step 1:

```bash
az ad app credential reset \
  --id <APP_ID> \
  --years 2
```

**Save the password!** This is your client secret - you won't see it again.

### Step 3: Grant Partner Center Permissions

This must be done in Azure Portal because Partner Center API isn't exposed via CLI:

1. Go to: https://portal.azure.com
2. Navigate to: **Azure Active Directory** → **App registrations**
3. Find: **ALSOURI Partner Center Integration**
4. Click: **API permissions** → **Add a permission**
5. Select: **APIs my organization uses**
6. Search: **Microsoft Partner Center** (or **Partner Center API**)
7. Select: **Delegated permissions** → Check **user_impersonation**
8. Click: **Add permissions**
9. Click: **Grant admin consent for ALSOURI LLC** (blue button at top)

### Step 4: Configure Environment Variables

```bash
cd /home/msalsouri/Projects/alsouri-org/partner-center
cp .env.example .env
nano .env
```

Edit `.env` and fill in:
```
PARTNER_CENTER_APP_ID=<your-app-id-from-step-1>
PARTNER_CENTER_SECRET=<your-client-secret-from-step-2>
PARTNER_CENTER_TENANT_ID=5a29c7e0-fe19-4c7a-9abd-2ef97ed043f1
```

### Step 5: Load Environment Variables

```bash
export $(cat .env | xargs)
```

Or for PowerShell:
```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
```

### Step 6: Test Authentication

```bash
pwsh ./scripts/test-partner-center-auth.ps1
```

If you see errors about permissions, try interactive authentication first:

```bash
pwsh ./scripts/test-partner-center-auth.ps1 -UseDeviceAuth
```

### Step 7: Explore Partner Center Data

```bash
# List all customers
pwsh ./scripts/get-customers.ps1

# Export customers to CSV
pwsh ./scripts/get-customers.ps1 -ExportCsv customers.csv

# Get usage analytics
pwsh ./scripts/get-usage-analytics.ps1

# Get specific customer analytics
pwsh ./scripts/get-usage-analytics.ps1 -CustomerId <customer-id> -Days 90
```

## 🔧 Troubleshooting

### "Authentication failed"
- Verify app ID and secret are correct
- Check that admin consent was granted (Step 3, #9)
- Ensure your account has Partner Center access

### "API call failed"
- Your app is authenticated but doesn't have Partner Center permissions
- Go back to Step 3 and verify permissions are granted
- Make sure you clicked "Grant admin consent"

### "No customers found"
- This is normal if you haven't added customers to Partner Center yet
- You can still test authentication and explore other cmdlets

## 📚 Useful Commands

```powershell
# List all available Partner Center cmdlets
Get-Command -Module PartnerCenter

# Get help for specific cmdlet
Get-Help Get-PartnerCustomer -Full

# View current Partner Center context
Get-PartnerContext

# Get organization profile
Get-PartnerOrganizationProfile

# List invoices
Get-PartnerInvoice

# Get MPN profile
Get-PartnerMpnProfile

# Explore customer subscriptions
Get-PartnerCustomerSubscription -CustomerId <customer-id>
```

## 🎯 Common Use Cases

1. **Customer Management**: Track and manage CSP customers
2. **Usage Analytics**: Monitor Azure consumption across customers
3. **Billing Automation**: Retrieve invoices and usage data
4. **Marketplace Management**: Manage Azure Marketplace offers
5. **Referral Tracking**: Monitor co-sell opportunities
6. **License Management**: Manage customer licenses and subscriptions

## 🔐 Security Notes

- `.env` file is gitignored - never commit secrets
- For production, use Azure Key Vault to store secrets
- Rotate client secrets every 6-12 months
- Monitor API usage in Partner Center portal
- Use service principal authentication (not user credentials) for automation

## 📖 Documentation

- [PartnerCenter PowerShell Module](https://docs.microsoft.com/powershell/partnercenter/)
- [Partner Center REST API](https://docs.microsoft.com/partner-center/develop/)
- [Partner Center Portal](https://partner.microsoft.com)
- [Azure AD App Registration](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps)

## 🆘 Need Help?

Review the detailed README.md in this directory for more information about:
- API permissions and security
- Certificate-based authentication
- Advanced automation scenarios
- Integration with Azure services
