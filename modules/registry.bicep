param acr_name string
param location string
param sku string = 'Premium'
param private_dns_zone_name string = 'privatelink.azurecr.io'
param subnetId string
param vnet_id string 

// Identity Configuration:
param registry_managed_identity_id string 
param registry_managed_identity_principal_id string 
param registry_managed_identity_client_id string
param registry_role_definition_id string = 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // AcrKeyVaultReader role for Azure Government

// Key Vault Configuration:
param registry_key_uri string // Key Vault URI for the customer-managed key

param default_tag_name string
param default_tag_value string

resource container_registry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acr_name
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  sku: {
    name: sku
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${registry_managed_identity_id}': {}
    }
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    encryption: {
      status: 'Enabled'
      keyVaultProperties: {
        identity: registry_managed_identity_client_id
        keyIdentifier: registry_key_uri
      }
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
  }
}

resource acr_role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(container_registry.id, registry_managed_identity_id, 'AcrKeyVaultReader')
  scope: container_registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', registry_role_definition_id) // AcrKeyVaultReader role
    principalId: registry_managed_identity_principal_id
  }
}

resource private_endpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: '${acr_name}-pe'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${acr_name}-plsc'
        properties: {
          privateLinkServiceId: container_registry.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${private_dns_zone.name}-link'
  parent: private_dns_zone
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet_id
    }
  }
}

resource registry_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: 'default'
  parent: private_endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output fqdn string = container_registry.properties.loginServer
output id string = container_registry.id 
output private_endpoint_id string = private_endpoint.id
