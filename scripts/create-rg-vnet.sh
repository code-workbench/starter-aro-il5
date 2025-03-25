# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

source "$(dirname "$0")/common.sh"

# Load variables from JSON file
if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

# Create the resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create the virtual network
az network vnet create --name $VNET_NAME --resource-group $RESOURCE_GROUP_NAME --subnet-name $SUBNET_NAME