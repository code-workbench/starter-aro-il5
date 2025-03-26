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

az deployment sub create --location $LOCATION \
    --template-file $TEMPLATE_FILE --parameters \
    project_prefix=$PROJECT_PREFIX \
    network_rg_name=$NETWORK_RESOURCE_GROUP_NAME \
    env_prefix=$ENV_PREFIX \
    location=$LOCATION \
    existing_network_name=$VNET_NAME \
    default_tag_name=$DEFAULT_TAG_NAME \
    default_tag_value=$DEFAULT_TAG_VALUE \
    service_principal_client_id=$SERVICE_PRINCIPAL_CLIENT_ID \
    service_principal_client_secret=$SERVICE_PRINCIPAL_CLIENT_SECRET

echo "Deployment completed successfully."