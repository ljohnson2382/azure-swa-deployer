# Publish docs/SOP to the repository Wiki
# Usage: pwsh -NoProfile -File .\scripts\publish-wiki.ps1

$ErrorActionPreference = 'Stop'

$wiki = 'https://github.com/ljohnson2382/azure-swa-deployer.wiki.git'
$tmp = Join-Path $env:TEMP 'wiki-tmp-azure-swa'
$repoRoot = (Get-Location).Path
$src = Join-Path $repoRoot 'docs\SOP'

Write-Host "Wiki: $wiki"
Write-Host "Temp clone path: $tmp"
Write-Host "Source SOP path: $src"

if (Test-Path $tmp) {
    Write-Host "Removing existing temp folder $tmp"
    Remove-Item -Recurse -Force $tmp
}

Write-Host "Cloning wiki..."
git clone $wiki $tmp
if ($LASTEXITCODE -ne 0) {
    Write-Error "git clone failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

if (-not (Test-Path $src)) {
    Write-Error "Source docs/SOP not found at $src"
    exit 2
}

Write-Host "Cleaning wiki clone (preserving .git)..."
Get-ChildItem -Path $tmp -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Copying SOP files to wiki clone..."
Copy-Item -Path (Join-Path $src '*') -Destination $tmp -Recurse -Force

# If README.md exists, copy it to Home.md for wiki Home page
$readme = Join-Path $tmp 'README.md'
if (Test-Path $readme) {
    Write-Host "Creating Home.md from README.md"
    Copy-Item -Path $readme -Destination (Join-Path $tmp 'Home.md') -Force
}

Set-Location $tmp

# Ensure commits have a local user
git config user.email 'actions@local' || Write-Host 'git config user.email failed'
git config user.name 'SOP Publisher Bot' || Write-Host 'git config user.name failed'

Write-Host "Checking for changes..."
$porcelain = git status --porcelain
Write-Host $porcelain

if (-not [string]::IsNullOrWhiteSpace($porcelain)) {
    git add -A
    git commit -m 'Publish docs/SOP to wiki'
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "Pushing to origin/$branch..."
    git push origin $branch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git push failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Host "Wiki updated successfully."
} else {
    Write-Host "No changes to publish to the wiki."
}

exit 0
