@description('The name of the managed identity to create')
param managedIdentityName string

param default_tag_name string
param default_tag_value string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: resourceGroup().location
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
