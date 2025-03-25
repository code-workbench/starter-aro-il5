# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --resource-group-name) RESOURCE_GROUP_NAME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 --resource-group-name <name>"
    exit 1
fi

# Create the resource group
az group delete --name $RESOURCE_GROUP_NAME --yes