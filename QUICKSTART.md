# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Prerequisites Check
```powershell
# Check if Azure CLI is installed
az --version

# Check PowerShell version (need 7.0+)
$PSVersionTable.PSVersion
```

### 2. Login to Azure
```powershell
az login
az account show
```

### 3. Customize Parameters
Edit `infra/parameters.json` with your values:
- `staticWebAppName`: Your app name (e.g., "swa-myapp-dev")
- `repositoryUrl`: Your GitHub repository URL
- `tags`: Your environment and client tags

### 4. Deploy Infrastructure
```powershell
# Validation mode (recommended first)
.\infra\deploy.ps1 -ParameterFile "infra\parameters.json" -ResourceGroupName "rg-swa-dev" -WhatIf

# Actual deployment
.\infra\deploy.ps1 -ParameterFile "infra\parameters.json" -ResourceGroupName "rg-swa-dev"
```

### 5. VS Code Tasks
Use `Ctrl+Shift+P` → "Run Task" to execute:
- **Validate Bicep Template** - Check syntax
- **Lint Bicep Template** - Code quality check
- **Deploy Infrastructure (What-If)** - Safe validation

## 🔧 Next Steps
1. Set up GitHub Actions secrets for automation
2. Create environment-specific parameter files
3. Configure custom domains (post-deployment)
4. Set up monitoring and alerts

## 📞 Need Help?
- Check the main [README.md](README.md) for detailed instructions
- Run tasks with `-WhatIf` to validate before deploying
- Use `az staticwebapp` commands for post-deployment management