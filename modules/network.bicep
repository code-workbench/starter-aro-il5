// Required Parameters:
param project_prefix string
param env_prefix string 
param location string 

// Configuration Paramters:
// Network Implementation:
param existing_network_name string = ''

// Optional Parameters:
param control_plane_cidr string = '10.0.1.0/18'
param worker_cidr string = '10.0.2.0/18'
param registry_cidr string = '10.0.3.0/24'
param key_vault_cidr string = '10.0.4.0/24'
param storage_cidr string = '10.0.5.0/24'
param jumpbox_cidr string = '10.0.6.0/24'
param bastion_cidr string = '10.0.7.0/24'

param deploy_jumpbox bool = false

resource virtual_network 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: existing_network_name
}

// Subnet for pod pods
resource control_plane_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${project_prefix}-${env_prefix}-master-plane'
  parent: virtual_network
  properties: {
    addressPrefix: control_plane_cidr
  }
  dependsOn: [
    virtual_network
  ]
}

resource worker_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${project_prefix}-${env_prefix}-worker-plane'
  parent: virtual_network
  properties: {
    addressPrefix: worker_cidr
  }
  dependsOn: [
    virtual_network, control_plane_subnet
  ]
}

resource storage_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${project_prefix}-${env_prefix}-storage'
  parent: virtual_network 
  properties: {
    addressPrefix: storage_cidr
  }
  dependsOn: [
    virtual_network, worker_subnet
  ]
}

resource registry_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${project_prefix}-${env_prefix}-registry'
  parent: virtual_network 
  properties: {
    addressPrefix: registry_cidr
  }
  dependsOn: [
    virtual_network, storage_subnet
  ]
}

resource keyvault_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${project_prefix}-${env_prefix}-key-vault'
  parent: virtual_network 
  properties: {
    addressPrefix: key_vault_cidr
  }
  dependsOn: [
    virtual_network, registry_subnet
  ]
}

resource jumpbox_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = if (deploy_jumpbox) {
  name: '${project_prefix}-${env_prefix}-jump-box'
  parent: virtual_network 
  properties: {
    addressPrefix: jumpbox_cidr
  }
  dependsOn: [
    virtual_network
  ]
}

// Bastion Subnet
resource bastion_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = if (deploy_jumpbox) {
  name: 'AzureBastionSubnet'
  parent: virtual_network 
  properties: {
    addressPrefix: bastion_cidr
  }
  dependsOn: [
    virtual_network, jumpbox_subnet
  ]
}

// Public IP Address for Bastion Host
resource bastion_pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deploy_jumpbox) {
  name: '${project_prefix}-${env_prefix}-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host
resource bastion_host 'Microsoft.Network/bastionHosts@2023-09-01' = if (deploy_jumpbox) {
  name: '${project_prefix}-${env_prefix}-bastion-host'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIPConfig'
        properties: {
          subnet: {
            id: bastion_subnet.id
          }
          publicIPAddress: {
            id: bastion_pip.id
          }
        }
      }
    ]
  }
}

output id string = virtual_network.id
output name string = virtual_network.name
output control_plane_subnet_id string = control_plane_subnet.id
output worker_subnet_id string = worker_subnet.id
output storage_subnet_id string = storage_subnet.id
output jumpbox_subnet_id string = jumpbox_subnet.id
output registry_subnet_id string = registry_subnet.id
output key_vault_subnet_id string = keyvault_subnet.id
output bastion_subnet_id string = bastion_subnet.id
output bastion_pip_id string = bastion_pip.id
