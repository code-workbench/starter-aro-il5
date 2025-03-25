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
az group delete --name $RESOURCE_GROUP_NAME --yes