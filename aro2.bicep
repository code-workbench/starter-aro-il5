targetScope = 'subscription'

@description('The name of the networking resource group')
param network_rg_name string

// Basic Parameters
@description('The project abbreviation')
param project_prefix string 

@description('The environment prefix (dev, test, prod)')
@minLength(1)
@maxLength(100)
param env_prefix string

@description('The location of the resource group')
param location string

// Network Implementation:
@description('The id of an existing network to be passed')
param existing_network_name string

// Subnet Configuration
param control_plane_cidr string = '10.0.64.0/18'
param worker_cidr string = '10.0.128.0/18'
param registry_cidr string = '10.0.192.0/18'
param key_vault_cidr string = '10.1.0.0/18'
param storage_cidr string = '10.1.64.0/18'
param jumpbox_cidr string = '10.1.128.0/18'
param bastion_cidr string = '10.1.192.0/18'

// Key Configuration:
param storage_account_key_name string = 'storage-key'
param registry_account_key_name string = 'registry-key'

// Managed Identity Configuration:
param storage_account_managed_identity_name string = 'storage-managed-identity'
param registry_account_managed_identity_name string = 'registry-managed-identity'

// ARO Network Configuration
param pod_cidr string = '10.0.192.0/18'
param service_cidr string = '10.1.0.0/22'

// Service Principal Configuration
@description('The name of the service principal')
@secure()
param service_principal_client_id string

@description('The secret for the service principal')
@secure()
param service_principal_client_secret string

// Jumpbox Configuration
param deploy_jumpbox bool = false
param jumpbox_username string = 'azureuser'
@secure()
param jumpbox_password string 

// Redhat Configuration:
@secure()
@description('The pull secret for Red Hat OpenShift')
param redhat_pull_secret string = ''
param control_plane_vm_size string = 'Standard_D8s_v3'
param pool_cluster_size string = 'Standard_D8s_v3'
param pool_cluster_disk_size int = 128
param pool_cluster_count int = 3

// Optional Custom Managed Image
@description('The ID of a custom managed image to use for the ARO cluster')
param custom_managed_image_id string = ''

// Tag Configuration:
param default_tag_name string
param default_tag_value string

//Suffix for resources
var uniqueSuffix = uniqueString(subscription().id)

resource network_resource_group 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: network_rg_name
}

resource shared_resource_group 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: '${project_prefix}-${env_prefix}-shared'
  location: location
}

resource aro_resource_group 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: '${project_prefix}-${env_prefix}-aro'
  location: location
}

resource aro_jumpbox_resource_group 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: '${project_prefix}-${env_prefix}-jumpbox'
  location: location
}

//Deploy into a existing network
module existing_network './modules/network.bicep' = {
  name: 'existing-network'
  scope: network_resource_group
  params: {
    location: location
    project_prefix: project_prefix
    env_prefix: env_prefix
    existing_network_name: existing_network_name
    control_plane_cidr: control_plane_cidr
    worker_cidr: worker_cidr
    registry_cidr: registry_cidr
    key_vault_cidr: key_vault_cidr
    storage_cidr: storage_cidr
    jumpbox_cidr: jumpbox_cidr
    bastion_cidr: bastion_cidr
    deploy_jumpbox: deploy_jumpbox
  }
}

// Deploy Key Vault first as it's required by other modules
module key_vault './modules/key-vault.bicep' = {
  name: 'key-vault'
  scope: shared_resource_group
  params: {
    key_vault_name: '${project_prefix}-${env_prefix}-key-${uniqueSuffix}'
    location: location
    subnet_id: existing_network.outputs.key_vault_subnet_id
    vnet_id: existing_network.outputs.id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
    storage_managed_identity_name: storage_account_managed_identity_name
    storage_account_key_name: storage_account_key_name
    registry_managed_identity_name: registry_account_managed_identity_name
    registry_account_key_name: registry_account_key_name
  }
}

// Deploy registry and storage in parallel after key vault
module registry './modules/registry.bicep' = {
  name: 'registry'
  scope: shared_resource_group
  params: {
    acr_name: '${project_prefix}${env_prefix}acr'
    location: location
    subnetId: existing_network.outputs.registry_subnet_id
    vnet_id: existing_network.outputs.id   
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
    registry_key_uri: key_vault.outputs.registry_key_uri
    registry_managed_identity_id: key_vault.outputs.registry_managed_identity_id
    registry_managed_identity_principal_id: key_vault.outputs.registry_managed_identity_principal_id
    registry_managed_identity_client_id: key_vault.outputs.registry_managed_identity_client_id
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage'
  scope: shared_resource_group
  params: {
    storage_account_name: '${project_prefix}${env_prefix}stg'
    location: location
    subnet_id: existing_network.outputs.storage_subnet_id
    vnet_id: existing_network.outputs.id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
    key_name: storage_account_key_name
    key_vault_uri: key_vault.outputs.key_vault_uri
    storage_managed_identity_id: key_vault.outputs.storage_managed_identity_id
  }
}

// Deploy ARO in parallel with registry and storage (since ARO doesn't depend on them)
module aro './modules/aro.bicep' = {
  name: 'aro'
  scope: aro_resource_group
  params: {
    aro_cluster_name: '${project_prefix}-${env_prefix}-aro'
    location: location
    project_prefix: project_prefix
    env_prefix: env_prefix
    control_plane_subnet_id: existing_network.outputs.control_plane_subnet_id
    worker_subnet_id: existing_network.outputs.worker_subnet_id
    control_plane_vm_size: control_plane_vm_size
    pool_cluster_size: pool_cluster_size
    pool_cluster_disk_size: pool_cluster_disk_size
    pool_cluster_count: pool_cluster_count
    service_cidr: service_cidr
    pod_cidr: pod_cidr
    cluster_domain: 'aro-${project_prefix}-${env_prefix}'
    service_principal_client_id: service_principal_client_id
    service_principal_client_secret: service_principal_client_secret
    redhat_pull_secret: redhat_pull_secret
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module jumpbox './modules/jump-box.bicep' = if (deploy_jumpbox) {
  name: 'jumpbox'
  scope: aro_jumpbox_resource_group
  params: {
    jumpbox_name: '${project_prefix}-${env_prefix}-jb'
    location: location
    admin_username: jumpbox_username
    admin_password: jumpbox_password
    custom_managed_image_id: custom_managed_image_id
    jumpbox_subnet_id: existing_network.outputs.jumpbox_subnet_id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

output registry_id string = registry.outputs.id
// output storage_id string = storage.outputs.id
output key_vault_id string = key_vault.outputs.id
output subnet_control_plane_id string = existing_network.outputs.control_plane_subnet_id
output subnet_worker_id string = existing_network.outputs.worker_subnet_id
output subnet_registry_id string = existing_network.outputs.registry_subnet_id
output subnet_key_vault_id string = existing_network.outputs.key_vault_subnet_id
output subnet_storage_id string = existing_network.outputs.storage_subnet_id
output vnet_id string = existing_network.outputs.id
output storage_managed_identity_id string = key_vault.outputs.storage_managed_identity_id
