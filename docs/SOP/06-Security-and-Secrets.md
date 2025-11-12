# 06 - Security and Secrets

Security is critical. Follow these principles when using the IaC framework.

## Principle of least privilege
- Service principals used for automated deployments should be scoped to the minimum required permissions.
- Prefer assigning roles at resource-group level rather than subscription-wide when possible.

## Secrets storage
- Use GitHub Secrets for CI/CD secrets (e.g., `AZURE_CREDENTIALS`).
- Use Azure Key Vault for runtime secrets and application secrets.
- Never store secrets in plaintext in parameter files, templates, or source control.

## Access and rotation
- Rotate service principal credentials periodically and after suspected compromise.
- Use short-lived credentials where supported.

## Auditing and logging
- Enable Azure Activity Logs and monitor for unexpected resource creation.
- Retain logs according to your organizational policy.

## Example: creating and storing `AZURE_CREDENTIALS`
1. Create service principal and capture JSON:
   ```bash
   az ad sp create-for-rbac --name "github-actions-swa-deployer" --role Contributor --scopes "/subscriptions/<sub>" --sdk-auth
   ```
2. Add output JSON to GitHub repository Secrets as `AZURE_CREDENTIALS`.

## Notes
- If you must store configuration files in the repo, ensure they contain no secrets (use placeholders only).
