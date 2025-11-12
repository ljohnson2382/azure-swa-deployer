#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys Azure Static Web App infrastructure using Bicep templates.

.DESCRIPTION
    This script deploys Azure Static Web Apps using Bicep templates and Azure CLI.
    It supports both parameter files and direct parameter input for flexible deployment scenarios.

.PARAMETER ParameterFile
    Path to the JSON parameter file containing deployment configuration.

.PARAMETER ResourceGroupName
    Name of the Azure Resource Group to deploy resources into.

.PARAMETER Location
    Azure region where the Resource Group should be created if it doesn't exist.

.PARAMETER StaticWebAppName
    Name for the Static Web App resource.

.PARAMETER RepositoryUrl
    GitHub repository URL for the Static Web App.

.PARAMETER RepositoryBranch
    Git branch to deploy from (default: main).

.PARAMETER SubscriptionId
    Azure subscription ID to deploy to.

.PARAMETER TenantId
    Azure tenant ID for authentication.

.PARAMETER WhatIf
    Performs a validation deployment without making changes.

.PARAMETER Force
    Skips confirmation prompts for resource group creation.

.EXAMPLE
    .\deploy.ps1 -ParameterFile "parameters.json" -ResourceGroupName "rg-swa-dev"

.EXAMPLE
    .\deploy.ps1 -StaticWebAppName "my-swa" -ResourceGroupName "rg-swa-prod" -RepositoryUrl "https://github.com/user/repo"

.NOTES
    Requirements:
    - Azure CLI 2.50+ with Bicep extension
    - PowerShell 7.0+
    - Appropriate Azure permissions for resource deployment
#>

[CmdletBinding(DefaultParameterSetName = 'ParameterFile')]
param(
    [Alias('parametersFile')]
    [Parameter(ParameterSetName = 'ParameterFile', Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$ParameterFile,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(ParameterSetName = 'DirectParams', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$StaticWebAppName,

    [Parameter(ParameterSetName = 'DirectParams')]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl,

    [Parameter(ParameterSetName = 'DirectParams')]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryBranch = 'main',

    [ValidateSet('West US 2', 'Central US', 'East US 2', 'West Europe', 'East Asia')]
    [string]$Location = 'West US 2',

    [string]$SubscriptionId,

    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [Alias('client')]
    [string]$Client,

    [Parameter(Mandatory = $false)]
    [Alias('env','environment')]
    [string]$EnvironmentName,

    [switch]$WhatIf,

    [switch]$Force
)

# Script variables
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$bicepTemplate = Join-Path $PSScriptRoot 'staticwebapp.bicep'
$deploymentName = "swa-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Color output functions
function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    if ($Host.UI.RawUI.ForegroundColor -and $Color -in @('Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan')) {
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Host $Message
    }
}

function Write-Success { param([string]$Message) Write-ColorOutput "✓ $Message" 'Green' }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠ $Message" 'Yellow' }
function Write-Error { param([string]$Message) Write-ColorOutput "✗ $Message" 'Red' }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ $Message" 'Cyan' }

# Validate prerequisites
function Test-Prerequisites {
    Write-Info "Validating prerequisites..."
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        if ([version]$azVersion.'azure-cli' -lt [version]'2.50.0') {
            throw "Azure CLI version 2.50.0+ required. Current: $($azVersion.'azure-cli')"
        }
        Write-Success "Azure CLI version: $($azVersion.'azure-cli')"
    }
    catch {
        Write-Error "Azure CLI not found or outdated. Please install Azure CLI 2.50+"
        throw
    }

    # Check Bicep template exists
    if (-not (Test-Path $bicepTemplate)) {
        Write-Error "Bicep template not found: $bicepTemplate"
        throw "Missing Bicep template file"
    }
    Write-Success "Bicep template found: $bicepTemplate"

    # Validate parameter file if provided
    if ($PSCmdlet.ParameterSetName -eq 'ParameterFile') {
        try {
            $params = Get-Content $ParameterFile -Raw | ConvertFrom-Json
            if (-not $params.parameters) {
                throw "Invalid parameter file format"
            }
            Write-Success "Parameter file validated: $ParameterFile"
        }
        catch {
            Write-Error "Invalid parameter file: $ParameterFile"
            throw
        }
    }
}

# Azure authentication and context setup
function Set-AzureContext {
    Write-Info "Setting up Azure context..."
    
    # Login check
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if (-not $account) {
            Write-Warning "Not logged in to Azure. Please login..."
            az login
        }
        Write-Success "Authenticated as: $($account.user.name)"
    }
    catch {
        Write-Warning "Authentication required..."
        az login
    }

    # Set subscription if provided
    if ($SubscriptionId) {
        Write-Info "Setting subscription: $SubscriptionId"
        az account set --subscription $SubscriptionId
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set subscription: $SubscriptionId"
        }
    }

    # Get current subscription
    $currentSub = az account show --output json | ConvertFrom-Json
    Write-Success "Using subscription: $($currentSub.name) ($($currentSub.id))"
}

# Resource Group management
function Ensure-ResourceGroup {
    Write-Info "Checking resource group: $ResourceGroupName"
    
    $rgExists = az group exists --name $ResourceGroupName --output tsv
    
    if ($rgExists -eq 'false') {
        if (-not $Force) {
            $response = Read-Host "Resource group '$ResourceGroupName' does not exist. Create it? (y/N)"
            if ($response -notin @('y', 'Y', 'yes', 'Yes')) {
                Write-Error "Resource group creation cancelled"
                throw "Resource group required for deployment"
            }
        }
        
        Write-Info "Creating resource group: $ResourceGroupName in $Location"
        az group create --name $ResourceGroupName --location $Location --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Resource group created successfully"
        } else {
            throw "Failed to create resource group"
        }
    } else {
        Write-Success "Resource group exists: $ResourceGroupName"
    }
}

# Deployment execution
function Invoke-Deployment {
    Write-Info "Starting deployment..."
    
    $deployArgs = @(
        'deployment', 'group', 'create'
        '--resource-group', $ResourceGroupName
        '--template-file', $bicepTemplate
        '--name', $deploymentName
        '--output', 'json'
    )

    # Add parameters based on parameter set
    if ($PSCmdlet.ParameterSetName -eq 'ParameterFile') {
        $deployArgs += @('--parameters', $ParameterFile)
    } else {
        $paramString = "staticWebAppName='$StaticWebAppName'"
        if ($RepositoryUrl) { $paramString += " repositoryUrl='$RepositoryUrl'" }
        if ($RepositoryBranch) { $paramString += " repositoryBranch='$RepositoryBranch'" }
        $paramString += " location='$Location'"
        $deployArgs += @('--parameters', $paramString)
    }

    # Add validation flag if WhatIf specified
    if ($WhatIf) {
        $deployArgs += '--validate-only'
        Write-Info "Performing validation deployment (--what-if)..."
    }

    try {
        $deploymentResult = & az @deployArgs
        
        if ($LASTEXITCODE -eq 0) {
            $result = $deploymentResult | ConvertFrom-Json
            
            if ($WhatIf) {
                Write-Success "Validation completed successfully"
                Write-Info "Deployment would create/update resources in: $ResourceGroupName"
            } else {
                Write-Success "Deployment completed successfully"
                Write-Info "Deployment name: $deploymentName"
                
                # Display outputs if available
                if ($result.properties.outputs) {
                    Write-Info "Deployment outputs:"
                    $result.properties.outputs.PSObject.Properties | ForEach-Object {
                        Write-Host "  $($_.Name): $($_.Value.value)" -ForegroundColor White
                    }
                }
            }
            
            return $result
        } else {
            throw "Deployment failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"
        throw
    }
}

# Main execution
try {
    Write-Info "Azure Static Web App Deployment Script"
    Write-Info "========================================"
    
    Test-Prerequisites
    Set-AzureContext

    # If ResourceGroupName isn't provided, derive it from client and environment
    if (-not $ResourceGroupName) {
        if ($Client -and $EnvironmentName) {
            $ResourceGroupName = "rg-$Client-$EnvironmentName"
            Write-Info "Derived Resource Group: $ResourceGroupName"
        } else {
            throw "Either -ResourceGroupName or both -Client and -EnvironmentName must be provided"
        }
    }

    # If StaticWebAppName not provided, derive from client/environment
    if (-not $StaticWebAppName -and $Client -and $EnvironmentName) {
        $StaticWebAppName = "swa-$Client-$EnvironmentName"
        Write-Info "Derived Static Web App name: $StaticWebAppName"
    }

    Ensure-ResourceGroup
    
    $deploymentResult = Invoke-Deployment
    
    Write-Success "Deployment process completed successfully!"
    
    if (-not $WhatIf -and $deploymentResult.properties.outputs.defaultHostname) {
        Write-Info "Your Static Web App is available at:"
        Write-Host "https://$($deploymentResult.properties.outputs.defaultHostname.value)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
finally {
    $ProgressPreference = 'Continue'
}