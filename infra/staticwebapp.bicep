@description('Name of the Static Web App. If empty, will be derived from clientName and environmentName using the convention swa-<client>-<env>')
param staticWebAppName string = ''

@description('Client short name (used to derive resource names when staticWebAppName is not provided)')
param clientName string = ''

@description('Environment name (dev, staging, prod). Used to derive resource names when staticWebAppName is not provided')
param environmentName string = ''

@description('Location for the Static Web App')
@allowed([
  'West US 2'
  'Central US'
  'East US 2'
  'West Europe'
  'East Asia'
])
param location string = 'West US 2'

@description('Repository URL for the Static Web App')
param repositoryUrl string = ''

@description('Branch name for the repository')
param repositoryBranch string = 'main'

@description('GitHub token for repository access (optional)')
@secure()
param repositoryToken string = ''

@description('Build configuration for the app')
param appLocation string = '/'

@description('API build configuration')
param apiLocation string = ''

@description('Output location for build artifacts')
param outputLocation string = ''

@description('SKU for the Static Web App')
@allowed([
  'Free'
  'Standard'
])
param sku string = 'Free'

@description('Tags to apply to the Static Web App')
param tags object = {}

@description('Enable staging environments')
param allowConfigFileUpdates bool = true

@description('Enterprise-grade edge enabled')
param enterpriseGradeCdnStatus string = 'Disabled'

// Default tags used when a caller doesn't provide them. Caller-supplied tags will
// overwrite these defaults when keys conflict.
var defaultTags = {
  Environment: 'dev'
  Owner: 'DevOps'
}

// Merge defaults with user-supplied tags so minimal input works.
var mergedTags = union(defaultTags, tags)

// Derive the effective Static Web App name using the naming convention when
// the caller does not supply a concrete name.
var effectiveStaticWebAppName = (empty(staticWebAppName) && !empty(clientName) && !empty(environmentName)) ? 'swa-${clientName}-${environmentName}' : staticWebAppName

@description('Enable optional GitHub integration (will wire repository URL/token into the resource)')
param enableGitHubIntegration bool = false

@description('Enable basic authentication configuration instructions (note: secrets/tokens are not stored in template outputs)')
param enableBasicAuth bool = false

// Create the Static Web App resource
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: effectiveStaticWebAppName
  location: location
  tags: mergedTags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
  // Wire GitHub repository information only when integration is enabled. Empty
  // values are still accepted by the service but we avoid setting values here
  // unless explicitly requested.
  repositoryUrl: (enableGitHubIntegration) ? repositoryUrl : ''
  branch: (enableGitHubIntegration) ? repositoryBranch : ''
  repositoryToken: (enableGitHubIntegration) ? repositoryToken : ''
    buildProperties: {
      appLocation: appLocation
      apiLocation: apiLocation
      outputLocation: outputLocation
    }
    allowConfigFileUpdates: allowConfigFileUpdates
    enterpriseGradeCdnStatus: enterpriseGradeCdnStatus
    stagingEnvironmentPolicy: 'Enabled'
  }
}

// Note: Custom domain configuration would be set up separately after deployment
// as it requires domain validation and DNS configuration

// Output the Static Web App details
@description('The name of the created Static Web App')
output staticWebAppName string = staticWebApp.name

@description('The default hostname of the Static Web App')
output defaultHostname string = staticWebApp.properties.defaultHostname

@description('The resource ID of the Static Web App')
output staticWebAppId string = staticWebApp.id

@description('The repository URL')
output repositoryUrl string = staticWebApp.properties.repositoryUrl

// Note: API keys and deployment tokens contain secrets and should be retrieved 
// separately using Azure CLI: az staticwebapp secrets list --name <app-name>

@description('Indicates whether basic auth guidance/configuration is enabled')
output basicAuthEnabled bool = enableBasicAuth
