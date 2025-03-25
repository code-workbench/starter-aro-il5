# !/bin/bash
# This script deletes a resource group in Azure.
# It requires the Azure CLI to be installed and configured.

source "$(dirname "$0")/common.sh"

check_jq_installed

if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

# Delete the resource group
echo "Deleting resource group: $RESOURCE_GROUP_NAME"
az group delete --name $RESOURCE_GROUP_NAME --yes
echo "Resource group $RESOURCE_GROUP_NAME deleted successfully."