# 04 - Disable Repository Deployment (this repo)

This repository is intentionally configured to NOT perform infrastructure deployments. This page documents why and how the repo has been made safe.

## Why disable deployments here
- This repo is a template/documentation repo. Running deployments here risks accidental provisioning against your Azure subscription.
- Production deployments must be controlled, auditable, and run from a dedicated deploy pipeline/repo.

## How deployments are disabled
- The workflow file was removed or renamed to a non-YAML extension (e.g., `.yml.txt`) so GitHub Actions will not recognize it.
- Any remaining workflow files, if present, should not contain `on:` triggers or `jobs:` definitions.

## How to re-enable (controlled)
1. Copy the `infra/` directory into a dedicated deploy repository (or a protected branch considered a deploy repo).
2. Create the GitHub Actions workflow in that deploy repo and set required secrets: `AZURE_CREDENTIALS`.
3. Use branch protection and environment approvals to require manual review for production runs.
4. Do not re-enable workflows in this template repository.

## Verification
To verify this repo will never run deployments:
- Confirm there are no `.yml` or `.yaml` workflow files under `.github/workflows`.
- Or ensure any workflow file has no `on:` or `jobs:` keys (i.e., is commented/disabled).

## Note about history
- Files present in past commits may have executed in the past if the workflows were enabled then. Historical runs are normal and appear in the Actions tab; disabling prevents future runs.
