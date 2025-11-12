# 03 - Deployment Procedures (for a deploy repo)

This SOP describes the recommended steps to deploy the Static Web App infrastructure in a controlled environment (a deploy repository or protected branch). Because this repository is a template repo, follow these steps in a separate deploy repo.

## Contract (inputs/outputs)
- Inputs
  - `clientName` (string)
  - `environmentName` (string) — e.g. `dev`, `staging`, `prod`
  - Parameter file path (e.g., `infra/parameters-<client>-<env>.json`)
- Outputs
  - Deployed Static Web App name and default hostname (from template outputs)

## Pre-deployment checklist
- Parameter file exists and follows naming conventions
- `AZURE_CREDENTIALS` secret configured in the deploy repo
- Branch protection and approvals set for `main` (for prod)
- Owners and reviewers assigned

## Standard Deployment Steps
1. Create or update parameter file for the target client and environment.
2. Run validation (what-if) using the PowerShell script:
   ```powershell
   .\infra\deploy.ps1 -ParameterFile infra\parameters-<client>-<env>.json -WhatIf
   ```
3. After validation, run a dry-run deployment in a test resource group.
4. Run full deployment (remove `-WhatIf`) once approvals are granted.

## Approvals and Protection
- For production, require at least 1 approver and use GitHub Environment protection rules.
- Keep deployment credentials tightly scoped (least privilege).

## Post-deployment actions
- Verify outputs: hostname, static web app name
- Confirm resource tags are present
- Update inventory and runbooks with the actual resource names and hostnames

## Audit and Logs
- Retain deployment logs (Action run logs and az CLI output) for 90 days
- Store deployment evidence in a secure location if required by policy
