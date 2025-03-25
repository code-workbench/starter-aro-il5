# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --resource-group-name) RESOURCE_GROUP_NAME="$2"; shift ;;
        --project-prefix) PROJECT_PREFIX="$2"; shift ;;
        --env-prefix) ENV_PREFIX="$2"; shift ;;
        --vnet-name) VNET_NAME="$2"; shift ;;
        --location) LOCATION="$2"; shift ;;
        --default-tag-name) DEFAULT_TAG_NAME="$2"; shift ;;
        --default-tag-value) DEFAULT_TAG_VALUE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z "$RESOURCE_GROUP_NAME" || -z "$VNET_NAME" || -z "$LOCATION" || -z "$PROJECT_PREFIX" || -z "$ENV_PREFIX" || -z "$DEFAULT_TAG_NAME" || -z "$DEFAULT_TAG_VALUE" ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 --resource-group-name <name> --project-prefix <name> --env-prefix <name> --vnet-name <name> --location <location> --default-tag-name <name> --default-tag-value <value>"
    exit 1
fi

TEMPLATE_FILE=$(realpath ./main.bicep)

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file $TEMPLATE_FILE --parameters project_prefix=$PROJECT_PREFIX env_prefix=$ENV_PREFIX location=$LOCATION existing_network_name=$VNET_NAME default_tag_name=$DEFAULT_TAG_NAME default_tag_value=$DEFAULT_TAG_VALUE