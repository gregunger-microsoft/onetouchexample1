// Bicep template for deploying an Azure App Service with a User Assigned Managed Identity, AAD Authentication, and other configurations.
param appRegistrationClientId string = '7e15ff63-82ef-4232-8e54-ac2318bfd85d'
param tenantId string = subscription().tenantId
param location string = resourceGroup().location
param createdDateTime string = utcNow('yyyy-MM-dd HH:mm:ss')

var managedIdentityName = 'mi-greg-delete-1'
var appServicePlanName = 'asp-greg-delete-1'
var appServicePlanSku = 'P1V3'
var appServiceName = 'app-greg-delete-1'
var acrLoginServer = 'acr8000.azurecr.io'
var imageName = 'simple-chat'
var imageTag = '2025-05-28_16'

var clientSecretSettingName = 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'

var tags = {
  Environment: 'test'
  Owner: 'gregunger@microsoft.com'
  CreatedDateTime: createdDateTime
  Project: 'GregTest'
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// --- App Service Plan (Linux) ---
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
    tier: split(appServicePlanSku, 'V')[0] // e.g., P1 from P1V3, B from B1. Adjust if SKU naming is different.
  }
  kind: 'linux' // As per script --is-linux
  properties: {
    reserved: true // Required for Linux plans
  }
}

// --- App Service (Web App for Containers) ---
resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'
      alwaysOn: appServicePlan.sku.tier != 'Free' && appServicePlan.sku.tier != 'Shared' && appServicePlan.sku.tier != 'Basic' // Example, P1V3 should be true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentity.properties.clientId
    } 
  }
  dependsOn: [
    // ACR role assignment might be needed here if ACR is in different RG/Sub and MI needs time
  ]
}

resource authSettingsV2 'Microsoft.Web/sites/config@2024-04-01' = {
  name: 'authsettingsV2'
  parent: appService // Link to the parent web app
  properties: {
    globalValidation: {
      requireAuthentication: true // Redirect unauthenticated requests to login
      unauthenticatedClientAction: 'RedirectToLoginPage' // Action for unauthenticated clients
      redirectToProvider: 'AzureActiveDirectory' // Default provider to redirect to
    }
    httpSettings: {
      forwardProxy: {
        convention: 'Standard' // or 'NoProxy'
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: appRegistrationClientId
          clientSecretSettingName: clientSecretSettingName // App setting name for client secret
          openIdIssuer: 'https://login.microsoftonline.us/${tenantId}/v2.0'
        }
        login: {
          disableWWWAuthenticate: false
        }
        validation: {
          allowedAudiences: [
            'api://${appRegistrationClientId}' // Replace with your application's client ID or other allowed audiences
            'https://${appServiceName}.azurewebsites.us' // Your app's URL
          ]
        }
      }
    }
    login: {
      tokenStore: {
        enabled: true // Enable token store to persist tokens
      }
    }
    platform: {
      enabled: true // Enable App Service Authentication/Authorization
      runtimeVersion: '~1' // Or a specific runtime version
    }
  }
}

resource appSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  name: 'appsettings'
  parent: appService
  properties: {
    CLIENT_ID: appRegistrationClientId
    MICROSOFT_PROVIDER_AUTHENTICATION_SECRET: 'YOUR_CLIENT_SECRET_VALUE'
    DOCKER_REGISTRY_SERVER_URL: 'https://${acrLoginServer}'
    DOCKER_REGISTRY_SERVER_PASSWORD: ''
    DOCKER_REGISTRY_SERVER_USERNAME: ''
    WEBSITES_CONTAINER_STARTUP_COMMAND: ''
  }
}
