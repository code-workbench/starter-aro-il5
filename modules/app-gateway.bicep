@description('The name of the Application Gateway')
param app_gateway_name string

@description('The location of the Application Gateway')
param location string

@description('The ID of the subnet for the Application Gateway')
param app_gateway_subnet_id string

@description('The frontend public IP address name for the Application Gateway')
param publicIpName string

@description('The SKU of the Application Gateway')
param sku_name string = 'WAF_v2'

@description('The capacity of the Application Gateway')
param capacity int = 2

@description('The ARO cluster domain name')
param aro_cluster_domain string

@description('The ID of the SSL certificate to be used by the Application Gateway')
param ssl_certificate_id string

@description('The default tag name')
param default_tag_name string

@description('The default tag value')
param default_tag_value string

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: app_gateway_name
  location: location
  sku: {
    name: sku_name
    tier: sku_name
    capacity: capacity
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: app_gateway_subnet_id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'httpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'aroBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: aro_cluster_domain
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', app_gateway_name, 'appGatewayFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', app_gateway_name, 'httpsPort')
          }
          protocol: 'Https'
          sslCertificate: ssl_certificate_id
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', app_gateway_name, 'httpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', app_gateway_name, 'aroBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', app_gateway_name, 'httpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
  tags: {
    '${default_tag_name}': default_tag_value
  }
}
