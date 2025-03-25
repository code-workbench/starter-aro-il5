@description('The name of the service principal')
param service_principal_name string

@description('The role to assign to the service principal')
//param role_definition_id string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Reader role Commercial
param role_definition_id string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Reader role Government

@description('The scope at which the role assignment applies')
param scope string = subscription().id

resource sp 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: service_principal_name
  location: resourceGroup().location
}

resource spPassword 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${service_principal_name}-password'
  location: resourceGroup().location
  properties: {
    principalId: sp.properties.principalId
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, service_principal_name, role_definition_id)
  properties: {
    roleDefinitionId: role_definition_id
    principalId: sp.properties.principalId
    scope: resourceGroup().id
  }
}

output servicePrincipalClientId string = sp.properties.clientId
output servicePrincipalClientSecret string = spPassword.properties.clientSecret
