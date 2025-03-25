# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --resource-group-name) RESOURCE_GROUP_NAME="$2"; shift ;;
        --vnet-name) VNET_NAME="$2"; shift ;;
        --location) LOCATION="$2"; shift ;;
        --subnet-name) SUBNET_NAME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z "$RESOURCE_GROUP_NAME" || -z "$VNET_NAME" || -z "$LOCATION" || -z "$SUBNET_NAME" ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 --resource-group-name <name> --vnet-name <name> --location <location> --subnet-name <name>"
    exit 1
fi

# Create the resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create the virtual network
az network vnet create --name $VNET_NAME --resource-group $RESOURCE_GROUP_NAME --subnet-name $SUBNET_NAME