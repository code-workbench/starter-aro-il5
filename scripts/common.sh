CONFIG_JSON="./envs/dev.json"

echo "Sourcing Functions..."
# Function to check if jq is installed
check_jq_installed() {
    echo "Checking if jq is installed..."
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if [[ $(uname -s) == "Linux" ]]; then
            sudo apt-get update && sudo apt-get install -y jq
        else
            echo "Unsupported OS for automatic jq installation. Please install jq manually."
            exit 1
        fi
    fi
}

# Function to load parameters from a JSON file
load_parameters() {
    local env_file=${1:-"$CONFIG_JSON"} # Use "$CONFIG_JSON" if $1 is not provided
    if [[ -f "$env_file" ]]; then
        echo "Loading parameters from $env_file"
        NETWORK_RESOURCE_GROUP_NAME=$(jq -r '.networkResourceGroupName' $CONFIG_JSON)
        PROJECT_PREFIX=$(jq -r '.projectPrefix' $CONFIG_JSON)
        ENV_PREFIX=$(jq -r '.envPrefix' $CONFIG_JSON)
        VNET_NAME=$(jq -r '.vnetName' $CONFIG_JSON)
        LOCATION=$(jq -r '.location' $CONFIG_JSON)
        SUBNET_NAME=$(jq -r '.subnetName' $CONFIG_JSON)
        DEFAULT_TAG_NAME=$(jq -r '.defaultTagName' $CONFIG_JSON)
        DEFAULT_TAG_VALUE=$(jq -r '.defaultTagValue' $CONFIG_JSON)
        SERVICE_PRINCIPAL_CLIENT_ID=$(jq -r '.servicePrincipalClientId' $CONFIG_JSON)
        SERVICE_PRINCIPAL_CLIENT_SECRET=$(jq -r '.servicePrincipalClientSecret' $CONFIG_JSON)
        SUBSCRIPTION_ID=$(jq -r '.subscriptionId' $CONFIG_JSON)
        DEPLOY_JUMPBOX=$(jq -r '.deployJumpBox' $CONFIG_JSON)
        
        output_parameters
    else 
        echo "Error: Configuration file $env_file not found."
        exit 1
    fi
}

output_parameters() {
    echo "Loaded parameters:"
    echo "--------------------------------"
    echo "Resource Group Name: $NETWORK_RESOURCE_GROUP_NAME"
    echo "Project Prefix: $PROJECT_PREFIX"
    echo "Environment Prefix: $ENV_PREFIX"
    echo "Virtual Network Name: $VNET_NAME"
    echo "Location: $LOCATION"
    echo "Default Tag Name: $DEFAULT_TAG_NAME"
    echo "Default Tag Value: $DEFAULT_TAG_VALUE"
    echo "Service Principal Client ID: $SERVICE_PRINCIPAL_CLIENT_ID"
    echo "Subscription ID: $SUBSCRIPTION_ID"
    echo "Deploy JumpBox: $DEPLOY_JUMPBOX"
    echo "--------------------------------"
}

parse_passed_parameters() {
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

    output_parameters
}