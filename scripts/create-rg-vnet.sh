# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

AZURE_REDHAT_OPENSHIFT_RP_CLIENT_ID="f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875"

source "$(dirname "$0")/common.sh"

check_jq_installed

# Load variables from JSON file
if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

# Create the resource group
echo -ne "Creating resource group: $NETWORK_RESOURCE_GROUP_NAME..."
az group create --name $NETWORK_RESOURCE_GROUP_NAME --location $LOCATION > /dev/null 2>&1
echo -e "\rResource group $NETWORK_RESOURCE_GROUP_NAME created successfully.                    "

# Create the virtual network
echo -ne "Creating virtual network: $VNET_NAME..."
az network vnet create --name $VNET_NAME --resource-group $NETWORK_RESOURCE_GROUP_NAME --subnet-name $SUBNET_NAME --address-prefix 10.0.0.0/15 > /dev/null 2>&1
echo -e "\rVirtual network $VNET_NAME created successfully.                    "

# Create role assignment for the service principal
echo -ne "Creating role assignment for service principal..."
az role assignment create --assignee $SERVICE_PRINCIPAL_CLIENT_ID --role "Network Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NETWORK_RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME > /dev/null 2>&1
echo -e "\rRole assignment for service principal created successfully.                    "

echo -ne "Setting up role assignment for Azure RedHat Open Shift RP..."
az role assignment create --assignee $AZURE_REDHAT_OPENSHIFT_RP_CLIENT_ID --role "Network Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NETWORK_RESOURCE_GROUP_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME > /dev/null 2>&1
echo -e "\rRole assignment for Azure RedHat Open Shift RP created successfully.                    "

echo "All resources deployed successfully!"