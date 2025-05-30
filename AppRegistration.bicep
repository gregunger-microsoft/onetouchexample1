extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.1.8-preview'

// Parameters (optional, but good practice for dynamic values)
param appRegistrationDisplayName string = 'MyExistingApp' // The display name of your existing app
param newRedirectUris array = [
  'https://myapp.azurewebsites.net/.auth/login/aad/callback'
  'https://localhost:44300/signin-oidc'
]
param newAppRoles array = [
  {
    allowedMemberTypes: [ 'Application' ]
    description: 'Access API as Application'
    displayName: 'Api.Access'
    isEnabled: true
    value: 'api.access' // This is the role value used in code
    id: guid('api.access', appRegistrationDisplayName) // Generate a stable GUID for the role
  }
  {
    allowedMemberTypes: [ 'User', 'Application' ]
    description: 'Read data as User or Application'
    displayName: 'Data.Read'
    isEnabled: true
    value: 'data.read'
    id: guid('data.read', appRegistrationDisplayName)
  }
]

resource existingAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  // To update an existing app registration, the 'uniqueName' should match the 'displayName'
  // of the existing application in Entra ID.
  uniqueName: appRegistrationDisplayName
  displayName: appRegistrationDisplayName // Ensure displayName also matches for clarity

  web: {
    redirectUris: newRedirectUris
    implicitGrantSettings: {
      enableIdTokenIssuance: true
      enableAccessTokenIssuance: true
    }
  }
  // For updating app roles:
  appRoles: newAppRoles
  // Add or update other properties as needed, e.g.:
  // api: {
  //   oauth2PermissionScopes: [
  //     {
  //       adminConsentDescription: 'Allows the app to read all user profiles.'
  //       adminConsentDisplayName: 'Read all user profiles'
  //       id: guid('user.read.all.scope', appRegistrationDisplayName)
  //       isEnabled: true
  //       type: 'Admin'
  //       userConsentDescription: 'Allows the app to read your profile.'
  //       userConsentDisplayName: 'Read your profile'
  //       value: 'User.Read.All'
  //     }
  //   ]
  // }
  // requiredResourceAccess: [ // Example for granting API permissions
  //   {
  //     resourceAppId: '00000003-0000-0000-c000-000000000000' // Microsoft Graph
  //     resourceAccess: [
  //       {
  //         id: guid('user.read') // Replace with actual GUID for User.Read if you know it, otherwise Graph will generate
  //         type: 'Scope' // For delegated permissions
  //       }
  //     ]
  //   }
  // ]
}

// Output the App ID if you need it for other resources
output appRegistrationId string = existingAppRegistration.appId
