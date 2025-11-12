# 01 - Prerequisites

This section lists the required software, accounts, and permissions needed to work with the Azure Static Web Apps IaC framework.

## Local Software
- PowerShell 7.x or later (recommended)
- Azure CLI (2.50+)
- Bicep CLI (via `az bicep`)
- Git
- (Optional) GitHub CLI (`gh`) for run and workflow management

## Accounts and Permissions
- Azure subscription with rights to create resource groups and Static Web Apps (Contributor at minimum for deploys)
- Azure AD service principal for automated pipelines (if you plan to enable CI/CD)
- GitHub repository with push rights to `main` or an appropriate branch

## Secrets and External Resources
- Do NOT commit secrets to this repository. Store the following in secure stores:
  - `AZURE_CREDENTIALS` for GitHub Actions (service principal JSON)
  - Repository tokens for GitHub integration (if used) — store in GitHub Secrets or Azure Key Vault

## Notes
- This repository is a template and documentation repository. Deployments are disabled here by design. Use a separate deploy repository or an environment-specific repository when executing real deployments.
