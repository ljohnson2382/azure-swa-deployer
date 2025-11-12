# 07 - Troubleshooting

Common problems, diagnostics, and remedies.

## Workflow ran unexpectedly
- Confirm there are no `.yml`/`.yaml` workflow files under `.github/workflows`.
- If a run is queued or in progress, cancel it via the GitHub UI or `gh run cancel`.

## Bicep build/lint errors
- Run locally: `az bicep build --file infra/staticwebapp.bicep` and `az bicep lint --file infra/staticwebapp.bicep`.
- Fix lint errors in the template and re-run validation.

## Deployment fails with permissions error
- Verify `AZURE_CREDENTIALS` service principal has Contributor role on the target scope.
- Confirm subscription and tenant IDs in the parameter file match the target subscription.

## Parameter mismatches
- Ensure the parameter file includes all required parameters; missing `staticWebAppName` will cause deployment failures.

## Logs and debug
- Use PowerShell `-Verbose` and Azure CLI `--debug` to collect verbose logs.
- Save deployment logs and the `az deployment group show` output for post-mortem.

## When in doubt
- Re-run a validation (what-if) to see intended changes without applying them.
- Ask a teammate or open an issue with logs attached.
