param location string
param key_vault_name string
param private_dns_zone_name string = 'privatelink.vaultcore.azure.net'
param key_vault_sku string = 'standard'
param key_vault_sku_family string = 'A'
param subnet_id string
param vnet_id string 

// Role Configuration
param storage_account_managed_identity_id string
param storage_account_role_definition_id string = 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User

// Key Configuration:
param storage_account_key_name string

// Tag Configuration:
param default_tag_name string
param default_tag_value string

var randomSuffix = uniqueString(resourceGroup().id, key_vault_name)
var maxLength = 24
var truncatedKeyVaultName = substring('${key_vault_name}-${randomSuffix}', 0, maxLength)
//var randomSuffix = uniqueString(subscription().subscriptionId, location)

resource key_vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: truncatedKeyVaultName
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    sku: {
      name: key_vault_sku
      family: key_vault_sku_family
    }
    enablePurgeProtection: true 
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: true 
    enabledForTemplateDeployment: true 
    enabledForDiskEncryption: true
    enableRbacAuthorization: true 
    tenantId: subscription().tenantId
    accessPolicies: []
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource storage_key 'Microsoft.KeyVault/vaults/keys@2024-11-01' = {
  name: storage_account_key_name
  parent: key_vault
  properties: {
    kty: 'RSA'
    keySize: 2048
    attributes: { 
      enabled: true
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: key_vault
  name: guid(key_vault.id, storage_account_managed_identity_id, storage_account_role_definition_id)
  properties: {
    roleDefinitionId: storage_account_role_definition_id
    principalId: storage_account_managed_identity_id
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource private_endpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: '${key_vault.name}-pe'
  location: location
  tags: {
    '${default_tag_name}': default_tag_value
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${key_vault.name}-plsc'
        properties: {
          privateLinkServiceId: key_vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnet_id
    }
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${private_dns_zone.name}-link'
  tags: {
    '${default_tag_name}': default_tag_value
  }
  parent: private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet_id
    }
  }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: 'default'
  parent: private_endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyVaultConfig1'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

output id string = key_vault.id
output key_vault_uri string = key_vault.properties.vaultUri
output private_endpoint_id string = private_endpoint.id
output private_dns_zone_id string = private_dns_zone.id
output name string = key_vault.name 
