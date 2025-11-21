# Microsoft Partner Center Integration

This directory contains scripts and configuration for integrating with Microsoft Partner Center APIs.

## Prerequisites

✅ **Installed** (as of Nov 21, 2024):
- PowerShell Core (`pwsh`) - version 7.x
- PartnerCenter PowerShell module (v3.0.10)
- Az PowerShell modules (v14.1.0)
- Azure CLI - authenticated to ALSOURI LLC tenant

## Azure Environment

- **Tenant**: ALSOURI LLC (`5a29c7e0-fe19-4c7a-9abd-2ef97ed043f1`)
- **Subscription**: MPN VM's (`ed72dd65-0d77-4f8c-8c44-a3025bf815ef`)
- **Domain**: alsouri.org
- **User**: info@alsouri.org

## Setup Steps

### 1. Create App Registration for Partner Center

Partner Center API requires an Azure AD app registration with specific permissions:

```bash
# Create app registration
az ad app create \
  --display-name "ALSOURI Partner Center Integration" \
  --sign-in-audience AzureADMyOrg

# Save the output - you'll need the appId (Client ID)
```

### 2. Configure API Permissions

The app needs Partner Center API permissions. This must be done in Azure Portal:

1. Go to [Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations
2. Find "ALSOURI Partner Center Integration"
3. Go to **API permissions** → **Add a permission**
4. Select **APIs my organization uses** → Search for "Microsoft Partner Center"
5. Add these permissions:
   - `user_impersonation` (Delegated)
   - Or configure Application permissions if running unattended

### 3. Create Client Secret or Certificate

**Option A: Client Secret (easier, recommended for testing)**

```bash
# Create client secret (expires in 2 years)
az ad app credential reset \
  --id <APP_ID_FROM_STEP_1> \
  --years 2

# Save the password (client secret) - you won't see it again!
```

**Option B: Certificate (more secure, recommended for production)**

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 \
  -keyout partner-center-key.pem \
  -out partner-center-cert.pem \
  -days 730 -nodes \
  -subj "/CN=ALSOURI Partner Center Integration"

# Upload certificate
az ad app credential reset \
  --id <APP_ID_FROM_STEP_1> \
  --cert @partner-center-cert.pem

# Keep partner-center-key.pem secure! Add to .gitignore
```

### 4. Configure Environment Variables

Create `.env` file (already in .gitignore):

```bash
# Partner Center App Credentials
PARTNER_CENTER_APP_ID=<your-app-id>
PARTNER_CENTER_SECRET=<your-client-secret>
PARTNER_CENTER_TENANT_ID=5a29c7e0-fe19-4c7a-9abd-2ef97ed043f1

# Partner Center Organization
PARTNER_CENTER_ACCOUNT_ID=<your-partner-center-account-id>
```

### 5. Test Authentication

```powershell
# Run authentication test
pwsh ./scripts/test-partner-center-auth.ps1
```

## Usage Examples

### Connect to Partner Center

```powershell
# Load credentials
$appId = $env:PARTNER_CENTER_APP_ID
$secret = $env:PARTNER_CENTER_SECRET
$tenantId = $env:PARTNER_CENTER_TENANT_ID

# Connect
$credential = New-Object System.Management.Automation.PSCredential($appId, (ConvertTo-SecureString $secret -AsPlainText -Force))
Connect-PartnerCenter -Credential $credential -TenantId $tenantId -ServicePrincipal
```

### Get Customer List

```powershell
# List all customers
Get-PartnerCustomer

# Get specific customer
Get-PartnerCustomer -CustomerId <customer-id>
```

### Retrieve Invoices

```powershell
# Get invoices
Get-PartnerInvoice

# Get specific invoice
Get-PartnerInvoice -InvoiceId <invoice-id>
```

### Manage Subscriptions

```powershell
# Get customer subscriptions
Get-PartnerCustomerSubscription -CustomerId <customer-id>

# Get Azure usage data
Get-PartnerCustomerUsage -CustomerId <customer-id>
```

## Security Best Practices

1. **Never commit secrets**: `.env` and `*.pem` files are gitignored
2. **Use Azure Key Vault**: For production, store secrets in Key Vault
3. **Rotate credentials**: Change client secrets every 6-12 months
4. **Principle of least privilege**: Only grant required API permissions
5. **Audit logs**: Monitor Partner Center API usage regularly

## Common Use Cases

1. **Customer Management**: Automated customer provisioning and management
2. **Marketplace Publishing**: Manage Azure Marketplace offers
3. **Usage Analytics**: Track customer Azure consumption
4. **Billing Automation**: Retrieve invoices and usage data
5. **License Management**: Manage CSP customer licenses
6. **Referral Management**: Track customer referrals and co-sell opportunities

## Troubleshooting

### Authentication Errors

```powershell
# Verify module version
Get-Module PartnerCenter -ListAvailable

# Test Azure CLI login
az account show

# Re-authenticate
Connect-PartnerCenter -UseDeviceAuthentication
```

### Permission Errors

- Ensure app has correct Partner Center API permissions
- Verify admin consent has been granted
- Check that service principal has Partner Center access

## Resources

- [Partner Center PowerShell Documentation](https://docs.microsoft.com/powershell/partnercenter/)
- [Partner Center REST API Reference](https://docs.microsoft.com/partner-center/develop/)
- [Azure AD App Registration Guide](https://docs.microsoft.com/azure/active-directory/develop/quickstart-register-app)
- [Partner Center Security Best Practices](https://docs.microsoft.com/partner-center/security-best-practices)

## Next Steps

1. Complete app registration (Step 1-3)
2. Configure `.env` file (Step 4)
3. Run authentication test (Step 5)
4. Review scripts in `./scripts/` directory
5. Customize automation scripts for your needs
