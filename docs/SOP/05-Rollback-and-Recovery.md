# 05 - Rollback and Recovery

This document describes how to rollback or recover from a failed deployment.

## Rollback principles
- Prefer recovering by redeploying a known-good parameter file + template version.
- For resource-level rollback (for example removing a partially created resource), use the Azure Portal or az CLI to remove unintended resources.

## Recommended rollback steps
1. Identify failing deployment run and gather logs and outputs.
2. Determine whether to revert to the previous stable template/parameter set.
3. If a rollback is needed, deploy the last known-good parameters and template version:
   ```bash
   az deployment group create --resource-group <rg> --template-file infra/staticwebapp.bicep --parameters infra/parameters-<client>-<env>-previous.json
   ```
4. If resources are partially created and need removal, delete the resource via `az resource delete` or `az group delete` (use caution).

## Emergency recovery
- If production is severely impacted, follow your organization's incident response runbook.
- Contact subscription administrators immediately if access or credentials are compromised.

## Validation after rollback
- Run what-if validation before finalizing any rollback that modifies production resources.
- Confirm endpoint availability and configuration after recovery.
