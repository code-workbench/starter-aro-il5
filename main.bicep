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
param control_plane_cidr string = '10.0.1.0/24'
param worker_cidr string = '10.0.2.0/24'
param registry_cidr string = '10.0.3.0/24'
param key_vault_cidr string = '10.0.4.0/24'
param storage_cidr string = '10.0.5.0/24'
param jumpbox_cidr string = '10.0.6.0/24'
param bastion_cidr string = '10.0.7.0/24'

// Jumpbox Configuration
param deploy_jumpbox bool = false

// Redhat Configuration:
@secure()
@description('The pull secret for Red Hat OpenShift')
param redhat_pull_secret string = ''
param control_plane_vm_size string = 'Standard_D4s_v3'
param pool_cluster_size string = 'Standard_D4s_v3'
param pool_cluster_disk_size int = 128
param pool_cluster_count int = 3

// Service Principal Configuration:
@description('The role to assign to the service principal')
//param role_definition_id string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Reader role Commercial
param role_definition_id string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Reader role Government

// Tag Configuration:
param default_tag_name string
param default_tag_value string

//Suffix for resources
var uniqueSuffix = uniqueString(resourceGroup().id)

//Deploy into a existing network
module existing_network './modules/network.bicep' = {
  name: 'existing-network'
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
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module registry './modules/registry.bicep' = {
  name: 'registry'
  params: {
    acr_name: '${project_prefix}${env_prefix}acr'
    location: location
    subnetId: existing_network.outputs.registry_subnet_id
    vnet_id: existing_network.outputs.id   
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    storage_account_name: '${project_prefix}${env_prefix}stg'
    location: location
    subnet_id: existing_network.outputs.storage_subnet_id
    vnet_id: existing_network.outputs.id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module key_vault './modules/key-vault.bicep' = {
  name: 'key-vault'
  params: {
    key_vault_name: '${project_prefix}-${env_prefix}-key-${uniqueSuffix}'
    location: location
    subnet_id: existing_network.outputs.key_vault_subnet_id
    vnet_id: existing_network.outputs.id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

module service_principal './modules/service-principal.bicep' = {
  name: 'service-principal'
  params: {
    service_principal_name: '${project_prefix}-${env_prefix}-cluster-sp'
    role_definition_id: role_definition_id
    scope: subscription().id
  }
}

module aro './modules/aro.bicep' = {
  name: 'aro'
  params: {
    aro_cluster_name: '${project_prefix}-${env_prefix}-aro'
    location: location
    control_plane_subnet_id: existing_network.outputs.control_plane_subnet_id
    worker_subnet_id: existing_network.outputs.worker_subnet_id
    control_plane_vm_size: control_plane_vm_size
    pool_cluster_size: pool_cluster_size
    pool_cluster_disk_size: pool_cluster_disk_size
    pool_cluster_count: pool_cluster_count
    service_principal_client_id: service_principal.outputs.servicePrincipalClientId
    service_principal_client_secret: service_principal.outputs.servicePrincipalClientSecret
    redhat_pull_secret: redhat_pull_secret
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

output registry_id string = registry.outputs.id
output storage_id string = storage.outputs.id
output key_vault_id string = key_vault.outputs.id
output subnet_control_plane_id string = existing_network.outputs.control_plane_subnet_id
output subnet_worker_id string = existing_network.outputs.worker_subnet_id
output subnet_registry_id string = existing_network.outputs.registry_subnet_id
output subnet_key_vault_id string = existing_network.outputs.key_vault_subnet_id
output subnet_storage_id string = existing_network.outputs.storage_subnet_id
output vnet_id string = existing_network.outputs.id
