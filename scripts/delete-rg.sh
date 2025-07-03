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
echo "Deleting ARO resource group..."
az group delete --name "$PROJECT_PREFIX-$ENV_PREFIX-aro-infra" --yes
echo "ARO resource group '$PROJECT_PREFIX-$ENV_PREFIX-aro-infra' deleted successfully."

echo "Deleting shared resource group..."
az group delete --name "$PROJECT_PREFIX-$ENV_PREFIX-shared" --yes
echo "Shared resource group '$PROJECT_PREFIX-$ENV_PREFIX-shared' deleted successfully."

echo "Deleting jumpbox resource group..."
az group delete --name "$PROJECT_PREFIX-$ENV_PREFIX-jumpbox" --yes
echo "Deleted jumpbox resource group..."

sleep 10s

echo "Deleting resource group: $NETWORK_RESOURCE_GROUP_NAME"
az group delete --name $NETWORK_RESOURCE_GROUP_NAME --yes
echo "Resource group $NETWORK_RESOURCE_GROUP_NAME deleted successfully."