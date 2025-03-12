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

param deploy_jumpbox bool = false

// Tag Configuration:
param default_tag_name string
param default_tag_value string

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
    key_vault_name: '${project_prefix}-${env_prefix}-kv'
    location: location
    subnet_id: existing_network.outputs.key_vault_subnet_id
    vnet_id: existing_network.outputs.id
    default_tag_name: default_tag_name
    default_tag_value: default_tag_value
  }
}

// module aro './modules/aro.bicep' = {
//   name: 'aro'
//   params: {
//     aro_cluster_name: '${project_prefix}-${env_prefix}-aro'
//     location: location
//     subnet_id: existing_network.outputs.control_plane_subnet_id

//     default_tag_name: default_tag_name
//     default_tag_value: default_tag_value
//   }
// }

output registry_id string = registry.outputs.id
output storage_id string = storage.outputs.id
output key_vault_id string = key_vault.outputs.id
output subnet_control_plane_id string = existing_network.outputs.control_plane_subnet_id
output subnet_worker_id string = existing_network.outputs.worker_subnet_id
output subnet_registry_id string = existing_network.outputs.registry_subnet_id
output subnet_key_vault_id string = existing_network.outputs.key_vault_subnet_id
output subnet_storage_id string = existing_network.outputs.storage_subnet_id
output vnet_id string = existing_network.outputs.id
