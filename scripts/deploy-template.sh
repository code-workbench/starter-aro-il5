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

TEMPLATE_FILE=$(realpath ./aro.bicep)

# Generate a random suffix for deployment name to prevent collisions
RANDOM_SUFFIX=$(openssl rand -hex 4)
DEPLOYMENT_NAME="aro-deployment-${RANDOM_SUFFIX}"

echo "Validating template..."
az deployment sub validate --location $LOCATION \
    --template-file $TEMPLATE_FILE --parameters \
    project_prefix=$PROJECT_PREFIX \
    network_rg_name=$NETWORK_RESOURCE_GROUP_NAME \
    env_prefix=$ENV_PREFIX \
    location=$LOCATION \
    existing_network_name=$VNET_NAME \
    default_tag_name=$DEFAULT_TAG_NAME \
    default_tag_value=$DEFAULT_TAG_VALUE \
    service_principal_client_id=$SERVICE_PRINCIPAL_CLIENT_ID \
    service_principal_client_secret=$SERVICE_PRINCIPAL_CLIENT_SECRET \
    jumpbox_username=$JUMPBOX_USERNAME \
    jumpbox_password=$JUMPBOX_PASSWORD \
    deploy_jumpbox=$DEPLOY_JUMPBOX \
    custom_managed_image_id=$CUSTOM_MANAGED_IMAGE_ID

if [[ $? -ne 0 ]]; then
    echo "Template validation failed. Please check the parameters and template."
    exit 1
fi

echo "Template validation passed."

echo "Starting deployment..."

START_TIME=$(date +%s)

echo "Deploying Bicep template with name: $DEPLOYMENT_NAME"

az deployment sub create --name $DEPLOYMENT_NAME --location $LOCATION \
    --template-file $TEMPLATE_FILE --parameters \
    project_prefix=$PROJECT_PREFIX \
    network_rg_name=$NETWORK_RESOURCE_GROUP_NAME \
    env_prefix=$ENV_PREFIX \
    location=$LOCATION \
    existing_network_name=$VNET_NAME \
    default_tag_name=$DEFAULT_TAG_NAME \
    default_tag_value=$DEFAULT_TAG_VALUE \
    service_principal_client_id=$SERVICE_PRINCIPAL_CLIENT_ID \
    service_principal_client_secret=$SERVICE_PRINCIPAL_CLIENT_SECRET \
    jumpbox_username=$JUMPBOX_USERNAME \
    jumpbox_password=$JUMPBOX_PASSWORD \
    deploy_jumpbox=$DEPLOY_JUMPBOX \
    custom_managed_image_id=$CUSTOM_MANAGED_IMAGE_ID \
    --no-wait

echo "Deployment started. Monitoring progress..."
while true; do
    STATUS=$(az deployment sub show --name $DEPLOYMENT_NAME --query "properties.provisioningState" -o tsv)
    echo "Deployment status: $STATUS"
    
    if [[ "$STATUS" == "Succeeded" ]]; then
        echo "Deployment completed successfully!"
        break
    elif [[ "$STATUS" == "Failed" ]]; then
        echo "Deployment failed!"
        az deployment sub show --name $DEPLOYMENT_NAME --query "properties.error" -o json
        exit 1
    fi
    
    echo "Waiting 60 seconds before next update..."
    sleep 60
done

END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

if [[ $? -eq 0 ]]; then
    echo "Deployment completed successfully. Execution time - ${MINUTES}:${SECONDS}"
else
    echo "Deployment failed. Execution time - ${MINUTES}:${SECONDS}" >&2
fi