# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

source "$(dirname "$0")/common.sh"

check_jq_installed

if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

TEMPLATE_FILE=$(realpath ./main.bicep)

echo "Deploying Bicep template..."
az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file $TEMPLATE_FILE --parameters project_prefix=$PROJECT_PREFIX env_prefix=$ENV_PREFIX location=$LOCATION existing_network_name=$VNET_NAME default_tag_name=$DEFAULT_TAG_NAME default_tag_value=$DEFAULT_TAG_VALUE
echo "Deployment completed successfully."