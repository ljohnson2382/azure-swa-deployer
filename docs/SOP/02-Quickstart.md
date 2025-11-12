# 02 - Quickstart

Follow these steps to validate the templates and run a safe local test (validation/what-if).

## 1) Validate the Bicep template

```powershell
# From repo root
az bicep build --file infra/staticwebapp.bicep
az bicep lint --file infra/staticwebapp.bicep
```

## 2) Create a parameter file for your environment

Copy the sample parameter file and update the placeholders:

```powershell
cp infra/parameters.json infra/parameters-dev.json
# Edit infra/parameters-dev.json and set client/environment specific values
```

Important: do not place tokens or secrets in the parameter file.

## 3) Run a validation (what-if)

Use the PowerShell script to run a `what-if` (validation) deployment against a target resource group. This will not create resources.

```powershell
.\infra\deploy.ps1 -ParameterFile infra\parameters-dev.json -ResourceGroupName rg-myclient-dev -WhatIf
```

If the script returns a successful validation, you can prepare to deploy in a non-production environment using the same pattern in a separate deploy repo.

## 4) Where to run real deployments

This repository is a template and is intentionally configured to not run deployments. To run real deployments:
- Copy `infra/` and the parameter file into a deploy repository
- Configure GitHub Secrets for that deploy repository
- Ensure the deploy repository workflow is enabled and reviewed by reviewers

