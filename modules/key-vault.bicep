param location string
param key_vault_name string
param private_dns_zone_name string = 'privatelink.vaultcore.azure.net'
param key_vault_sku string = 'standard'
param key_vault_sku_family string = 'A'
param subnet_id string
param vnet_id string 

// Managed Identity Configuration:
param storage_managed_identity_name string = 'storage-managed-identity'
param registry_managed_identity_name string = 'registry-managed-identity'
param app_gateway_managed_identity_name string = 'app-gateway-managed-identity'

// Role Configuration
param storage_account_role_definition_id string = 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
param registry_account_role_definition_id string = 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
param app_gateway_account_role_definition_id string = 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User

// Key Configuration:
param storage_account_key_name string
param registry_account_key_name string

// SSL Certificate Configuration:
param certificate_name string = 'app-gateway-ssl-cert'
param certificate_common_name string
param certificate_content_type string = 'application/x-pkcs12' // or 'application/x-x509-ca-cert'

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
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: true 
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true 
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true 
    enablePurgeProtection: true 
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Managed Identities for storage 
resource storage_managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: storage_managed_identity_name
  location: resourceGroup().location
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource registry_managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: registry_managed_identity_name
  location: resourceGroup().location
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource app_gateway_managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: app_gateway_managed_identity_name
  location: resourceGroup().location
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

// Managed Identity Role Assignments
resource storage_roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: key_vault
  name: guid(key_vault.id, storage_managed_identity.id, storage_account_role_definition_id)
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${storage_account_role_definition_id}' // Key Vault Crypto Service Encryption User
    principalId: storage_managed_identity.properties.principalId
  }
}

resource registry_roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: key_vault
  name: guid(key_vault.id, registry_managed_identity.id, registry_account_role_definition_id)
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${registry_account_role_definition_id}' // Key Vault Crypto Service Encryption User
    principalId: registry_managed_identity.properties.principalId
  }
}

resource app_gateway_roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: key_vault
  name: guid(key_vault.id, app_gateway_managed_identity.id, app_gateway_account_role_definition_id)
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/${app_gateway_account_role_definition_id}' // Key Vault Crypto Service Encryption User
    principalId: app_gateway_managed_identity.properties.principalId
  }
}

// Customer Managed Keys
resource storage_key 'Microsoft.KeyVault/vaults/keys@2024-11-01' = {
  parent: key_vault
  name: storage_account_key_name
  properties: {
    attributes: {
      enabled: true
      exportable: false
    }
    kty: 'RSA'
    keySize: 2048
  }
}

resource registry_key 'Microsoft.KeyVault/vaults/keys@2024-11-01' = {
  parent: key_vault
  name: registry_account_key_name
  properties: {
    attributes: {
      enabled: true
      exportable: false
    }
    kty: 'RSA'
    keySize: 2048
  }
}

// DNS Configuration:
resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
  tags: {
    '${default_tag_name}': default_tag_value
  }
}

resource ssl_certificate 'Microsoft.Web/certificates@2024-04-01' = {
  name: certificate_name
  location: location
  properties: {
    keyVaultId: key_vault.id
    keyVaultSecretName: certificate_name
    canonicalName: certificate_common_name
    hostNames: [
      certificate_common_name
    ]
    pfxBlob: ''
    password: ''
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
output storage_managed_identity_id string = storage_managed_identity.id
output registry_managed_identity_id string = registry_managed_identity.id
output registry_managed_identity_client_id string = registry_managed_identity.properties.clientId
output registry_managed_identity_principal_id string = registry_managed_identity.properties.principalId
output app_gateway_managed_identity_id string = app_gateway_managed_identity.id
output app_gateway_managed_identity_client_id string = app_gateway_managed_identity.properties.clientId
output app_gateway_managed_identity_principal_id string = app_gateway_managed_identity.properties.principalId
output storage_key_uri string = storage_key.properties.keyUri
output registry_key_uri string = registry_key.properties.keyUri
output app_gateway_ssl_cert_id string = ssl_certificate.id
