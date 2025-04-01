// Add a parameter for the key name and key type
param key_name string
param key_type string = 'RSA' // Options: 'RSA', 'RSA-HSM', 'EC', 'EC-HSM'
param key_size int = 2048 // Key size for RSA keys (e.g., 2048, 3072, 4096)

// Add the key resource
resource key_vault_key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  name: '${key_vault.name}/${key_name}'
  properties: {
    kty: key_type
    keySize: key_size
    attributes: {
      enabled: true
    }
  }
}

// Optionally, output the key ID
output key_id string = key_vault_key.id
