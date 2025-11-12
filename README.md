# Azure Static Web Apps Infrastructure-as-Code Framework

A comprehensive, reusable infrastructure-as-code deployment framework for Azure Static Web Apps using Bicep templates, PowerShell scripts, and GitHub Actions workflows. This solution supports multiple clients and environments through parameterization and modular design.

## 🏗️ Project Structure

```
azure-swa-deployer/
├── infra/
│   ├── staticwebapp.bicep      # Main Bicep template for Static Web App
│   ├── parameters.json         # Sample parameter file
│   └── deploy.ps1             # PowerShell deployment script
├── .github/
│   ├── workflows/
│   │   └── deploy-infra.yml   # GitHub Actions deployment workflow
│   └── copilot-instructions.md # Development guidelines
└── README.md                  # This file
```

## 🚀 Features

- **Modular Bicep Templates**: Parameterized infrastructure definitions
- **Cross-platform PowerShell Scripts**: Automated deployment with comprehensive error handling
- **GitHub Actions Integration**: CI/CD pipeline for infrastructure deployment
- **Multi-environment Support**: Environment-specific configurations through parameter files
- **Validation Support**: What-if deployments for safe validation
- **Comprehensive Logging**: Detailed deployment logs and status reporting

## 📋 Prerequisites

### Local Development
- [Azure CLI 2.50+](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) with Bicep extension
- [PowerShell Core 7.0+](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- Azure subscription with appropriate permissions

### GitHub Actions
- Azure service principal with Contributor access
- GitHub repository secrets configured (see [Setup](#setup))

## ⚙️ Setup

### 1. Azure Service Principal (for GitHub Actions)

Create a service principal for GitHub Actions authentication:

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-swa-deployer" \
  --role "Contributor" \
  --scopes "/subscriptions/<subscription-id>" \
  --sdk-auth

# Output will be used for AZURE_CREDENTIALS secret
```

### 2. GitHub Repository Secrets

Add the following secrets to your GitHub repository (`Settings` > `Secrets and variables` > `Actions`):

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `AZURE_CREDENTIALS` | Azure service principal credentials | JSON output from service principal creation |

### 3. Configure Parameters

Copy and customize the parameter file for your environment:

```bash
cp infra/parameters.json infra/parameters-prod.json
```

Edit the parameter file to match your requirements:

```json
{
  "parameters": {
    "staticWebAppName": {
      "value": "swa-yourapp-prod"
    },
    "repositoryUrl": {
      "value": "https://github.com/yourorg/your-repo"
    },
    "tags": {
      "value": {
        "Environment": "Production",
        "Client": "YourClient",
        "CostCenter": "IT-001"
      }
    }
  }
}
```

## ✅ Checklist for customizing deployments per client

Before deploying for a new client/environment, make sure to:

- Copy `infra/parameters.json` to a client/environment specific file (e.g. `infra/parameters-contoso-dev.json`).
- Update `staticWebAppName` to follow naming conventions (e.g. `swa-<client>-<env>`).
- Set `tags` to include `Environment`, `Client`, `CostCenter`, and `Owner`.
- If you want Azure to link to your repo and enable GitHub Actions automations, set `enableGitHubIntegration` to `true` and provide a `repositoryUrl` and `repositoryToken` via secure means (do NOT store the token in the parameters file in the repo).
- Use `-WhatIf` validation first to ensure no unexpected changes.

Important: this repository does not store any secrets (tokens, credentials, or passwords). Store sensitive values securely in GitHub Secrets, Azure Key Vault, or another secret store and reference them at deployment time.

### 🧩 Customize for a New Client

To deploy for a new client:

- [ ] Duplicate `infra/parameters.json` and rename it (e.g., `parameters-acme.json`)
- [ ] Update values:
  - `swaName`: `"swa-acmecorp-prod"`
  - `repoUrl`: `"https://github.com/acme-corp/website"`
  - `branch`: `"main"`
  - `tags`: update `client`, `project`, `owner`, etc.
- [ ] Run the deployment:
  - PowerShell: `.\\infra\\deploy.ps1 -parametersFile ./infra/parameters-acme.json`
  - Or trigger the GitHub Action manually (see the workflow in `.github/workflows/deploy-infra.yml`)

Be sure to validate with `-WhatIf` before performing a production deployment.

## 🖥️ Local Deployment

### Using PowerShell Script

**Deploy with parameter file:**
```powershell
.\infra\deploy.ps1 -ParameterFile "infra\parameters.json" -ResourceGroupName "rg-<client>-<env>"
```

**Deploy with direct parameters:**
```powershell
.\infra\deploy.ps1 -StaticWebAppName "my-swa" -ResourceGroupName "rg-swa-dev" -RepositoryUrl "https://github.com/user/repo"
```

**Validation mode (What-if):**
```powershell
.\infra\deploy.ps1 -ParameterFile "infra\parameters.json" -ResourceGroupName "rg-<client>-<env>" -WhatIf
```

### Using Azure CLI Directly

```bash
# Create resource group (example)
az group create --name "rg-<client>-<env>" --location "West US 2"

# Deploy infrastructure
az deployment group create \
  --resource-group "rg-<client>-<env>" \
  --template-file "infra/staticwebapp.bicep" \
  --parameters "infra/parameters.json"
```

## 🔄 GitHub Actions Deployment

### Automatic Deployment

The workflow automatically deploys infrastructure when:
- Changes are pushed to the `main` branch in the `infra/` folder
- The workflow file itself is modified

### Manual Deployment

Trigger manual deployments via GitHub Actions:

1. Go to `Actions` tab in your repository
2. Select `Deploy Azure Static Web App Infrastructure`
3. Click `Run workflow`
4. Configure parameters:
   - **Environment**: `dev`, `staging`, or `prod`
   - **Parameter File**: Parameter file to use (default: `parameters.json`)
   - **Validation Mode**: Run in what-if mode without making changes

### Workflow Features

- **Environment Protection**: Production deployments can require approval
- **Validation**: Bicep linting and template validation
- **What-if Support**: Safe validation without resource changes
- **Deployment Summaries**: Comprehensive deployment reports
- **Output Capture**: Automatically captures and displays deployment outputs

## 📊 Bicep Template Parameters

| Parameter | Type | Description | Default | Required |
|-----------|------|-------------|---------|----------|
| `staticWebAppName` | string | Name of the Static Web App | - | ✅ |
| `location` | string | Azure region | `West US 2` | ❌ |
| `repositoryUrl` | string | GitHub repository URL | `''` | ❌ |
| `repositoryBranch` | string | Git branch to deploy | `main` | ❌ |
| `repositoryToken` | securestring | GitHub token | `''` | ❌ |
| `appLocation` | string | App source location | `/` | ❌ |
| `apiLocation` | string | API source location | `''` | ❌ |
| `outputLocation` | string | Build output location | `''` | ❌ |
| `sku` | string | Static Web App SKU | `Free` | ❌ |
| `tags` | object | Resource tags | `{}` | ❌ |

## 🔧 Customization

### Multi-client Support

Create separate parameter files for each client:

```
infra/
├── parameters-client1-dev.json
├── parameters-client1-prod.json
├── parameters-client2-dev.json
└── parameters-client2-prod.json
```

### Environment-specific Workflows

Create environment-specific workflows by copying and modifying the base workflow:

```yaml
# .github/workflows/deploy-prod.yml
name: Deploy Production Infrastructure
on:
  push:
    branches: [main]
    paths: ['infra/parameters-prod.json']
```

### Custom Resource Naming

Follow Azure naming conventions in your parameter files:

```json
{
  "staticWebAppName": {
    "value": "swa-[client]-[app]-[env]"
  }
}
```

## 🔍 Troubleshooting

### Common Issues

**PowerShell Execution Policy**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Azure CLI Not Found**
```bash
# Install Azure CLI
winget install Microsoft.AzureCLI
```

**Bicep Extension Missing**
```bash
az bicep install
az bicep upgrade
```

### Deployment Validation

Always run what-if deployments before production:

```powershell
.\infra\deploy.ps1 -ParameterFile "infra\parameters-prod.json" -ResourceGroupName "rg-swa-prod" -WhatIf
```

### Debug Information

Enable verbose logging in PowerShell:

```powershell
$VerbosePreference = "Continue"
.\infra\deploy.ps1 -ParameterFile "infra\parameters.json" -ResourceGroupName "rg-swa-dev" -Verbose
```

## 📚 Additional Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Bicep Language Reference](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an [Issue](https://github.com/your-org/azure-swa-deployer/issues)
- Check the [Wiki](https://github.com/your-org/azure-swa-deployer/wiki)
- Review existing [Discussions](https://github.com/your-org/azure-swa-deployer/discussions)

---

**Built with ❤️ for Azure Static Web Apps infrastructure automation**