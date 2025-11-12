# Remove 08-Change-Log.md from the GitHub Wiki repo
# Usage: pwsh -NoProfile -File .\scripts\remove-wiki-changelog.ps1

$ErrorActionPreference = 'Stop'

$wiki = 'https://github.com/ljohnson2382/azure-swa-deployer.wiki.git'
$tmp = Join-Path $env:TEMP 'wiki-tmp-azure-swa'

if (Test-Path $tmp) {
    Write-Host "Removing existing temp folder $tmp"
    Remove-Item -Recurse -Force $tmp
}

Write-Host "Cloning wiki repo: $wiki"
git clone $wiki $tmp
if ($LASTEXITCODE -ne 0) {
    Write-Error "git clone failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Set-Location $tmp

$file = '08-Change-Log.md'
if (-not (Test-Path $file)) {
    Write-Host "No change log file in wiki; nothing to remove"
    exit 0
}

Write-Host "Removing $file from wiki"
git rm $file
if ($LASTEXITCODE -ne 0) {
    Write-Error "git rm failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

git commit -m 'chore: remove SOP change log from wiki (managed in repo removed)'
if ($LASTEXITCODE -ne 0) { Write-Host 'git commit returned non-zero (no changes?)' }

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Pushing removal to origin/$branch"
git push origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "git push failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host 'Wiki change log removed and pushed.'
