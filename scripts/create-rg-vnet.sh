# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

source "$(dirname "$0")/common.sh"

check_jq_installed

# Load variables from JSON file
if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

# Create the resource group
echo "Creating resource group: $NETWORK_RESOURCE_GROUP_NAME"
az group create --name $NETWORK_RESOURCE_GROUP_NAME --location $LOCATION
echo "Resource group $NETWORK_RESOURCE_GROUP_NAME created successfully."

# Create the virtual network
echo "Creating virtual network: $VNET_NAME"
az network vnet create --name $VNET_NAME --resource-group $NETWORK_RESOURCE_GROUP_NAME --subnet-name $SUBNET_NAME --address-prefix 10.0.0.0/15
echo "Virtual network $VNET_NAME created successfully."

# Get the virtual network resource ID
echo "Fetching the resource ID for virtual network: $VNET_NAME"
VNET_ID=$(az network vnet show --name "$VNET_NAME" --resource-group "$NETWORK_RESOURCE_GROUP_NAME" --query "id" --output tsv)
echo "Virtual network resource ID: $VNET_ID"

# Create role assignment for the service principal
echo "Creating role assignment for service principal..."
echo ""
echo "SERVICE_PRINCIPAL_CLIENT_ID - $SERVICE_PRINCIPAL_CLIENT_ID"
echo "VNET_ID - $VNET_ID"
echo ""
echo "az role assignment create --assignee \"$SERVICE_PRINCIPAL_CLIENT_ID\" --role b24988ac-6180-42a0-ab88-20f7382dd24c --scope \"$VNET_ID\""

echo "Role assignment for service principal created successfully."