@description('Name of the Static Web App')
param staticWebAppName string

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

// Create the Static Web App resource
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: repositoryBranch
    repositoryToken: repositoryToken
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
