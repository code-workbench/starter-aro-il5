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
        JUMPBOX_USERNAME=$(jq -r '.jumpboxUsername' $CONFIG_JSON)
        JUMPBOX_PASSWORD=$(jq -r '.jumpboxPassword' $CONFIG_JSON)
        CUSTOM_MANAGED_IMAGE_ID=$(jq -r '.custom_managed_image_id' $CONFIG_JSON)
        
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
    echo "JumpBox Username: $JUMPBOX_USERNAME"
    echo "Custom Managed Image ID: $CUSTOM_MANAGED_IMAGE_ID"
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check deployment status for a resource group
check_deployment_status() {
    local resource_group=$1
    local rg_type=$2
    
    print_status $BLUE "Checking deployment status for: $resource_group ($rg_type)"
    echo "============================================="
    
    # Check if resource group exists
    if ! az group show --name "$resource_group" &>/dev/null; then
        print_status $RED "❌ Resource group '$resource_group' does not exist"
        echo ""
        return 1
    fi
    
    print_status $GREEN "✅ Resource group '$resource_group' exists"
    
    # Get deployment history
    local deployments=$(az deployment group list --resource-group "$resource_group" --query '[].{name:name, provisioningState:properties.provisioningState, timestamp:properties.timestamp}' --output table 2>/dev/null)
    
    if [[ -z "$deployments" || "$deployments" == "[]" ]]; then
        print_status $YELLOW "⚠️  No deployments found in resource group '$resource_group'"
    else
        echo ""
        print_status $BLUE "Recent deployments:"
        echo "$deployments"
        
        # Get the latest deployment status
        local latest_deployment=$(az deployment group list --resource-group "$resource_group" --query '[0].{name:name, state:properties.provisioningState, timestamp:properties.timestamp}' --output json 2>/dev/null)
        
        if [[ -n "$latest_deployment" && "$latest_deployment" != "null" ]]; then
            local deployment_name=$(echo "$latest_deployment" | jq -r '.name')
            local deployment_state=$(echo "$latest_deployment" | jq -r '.state')
            local deployment_time=$(echo "$latest_deployment" | jq -r '.timestamp')
            
            echo ""
            print_status $BLUE "Latest deployment details:"
            echo "Name: $deployment_name"
            echo "State: $deployment_state"
            echo "Timestamp: $deployment_time"
            
            case "$deployment_state" in
                "Succeeded")
                    print_status $GREEN "✅ Latest deployment succeeded"
                    ;;
                "Failed")
                    print_status $RED "❌ Latest deployment failed"
                    # Get error details
                    local error_details=$(az deployment group show --resource-group "$resource_group" --name "$deployment_name" --query 'properties.error' --output json 2>/dev/null)
                    if [[ -n "$error_details" && "$error_details" != "null" ]]; then
                        echo ""
                        print_status $RED "Error details:"
                        echo "$error_details" | jq -r '.message // "No error message available"'
                    fi
                    ;;
                "Running")
                    print_status $YELLOW "⏳ Deployment is currently running"
                    ;;
                "Canceled")
                    print_status $YELLOW "⚠️  Deployment was canceled"
                    ;;
                *)
                    print_status $YELLOW "⚠️  Deployment state: $deployment_state"
                    ;;
            esac
        fi
    fi
    
    # List resources in the resource group
    # echo ""
    # print_status $BLUE "Resources in resource group:"
    # local resources=$(az resource list --resource-group "$resource_group" --query '[].{name:name, type:type, location:location}' --output table 2>/dev/null)
    
    # if [[ -z "$resources" || "$resources" == "[]" ]]; then
    #     print_status $YELLOW "⚠️  No resources found in resource group '$resource_group'"
    # fi
    
    echo ""
    echo "============================================="
    echo ""
}

# Function to display summary
display_summary() {
    local shared_rg=$1
    local aro_rg=$2
    local jumpbox_rg=$3
    local network_rg=$4
    
    print_status $BLUE "DEPLOYMENT STATUS SUMMARY"
    echo "============================================="
    
    # Check each resource group and track overall status
    local overall_status="SUCCESS"
    
    for rg in "$shared_rg" "$aro_rg" "$jumpbox_rg" "$network_rg"; do
        if az group show --name "$rg" &>/dev/null; then
            local latest_state=$(az deployment group list --resource-group "$rg" --query '[0].properties.provisioningState' --output tsv 2>/dev/null)
            latest_state=$(echo "$latest_state" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
            case "$latest_state" in
                "succeeded")
                    print_status $GREEN "✅ $rg: Deployment succeeded"
                    ;;
                "failed")
                    print_status $RED "❌ $rg: Deployment failed"
                    overall_status="FAILED"
                    ;;
                "running"|"accepted"|"creating"|"updating"|"inprogress")
                    print_status $YELLOW "⏳ $rg: Deployment in progress (${latest_state})"
                    overall_status="IN_PROGRESS"
                    ;;
                "")
                    print_status $YELLOW "⚠️  $rg: No deployments found"
                    if [[ "$overall_status" == "SUCCESS" ]]; then
                        overall_status="WARNING"
                    fi
                    ;;
                *)
                    print_status $YELLOW "⚠️  $rg: Status unknown (${latest_state})"
                    if [[ "$overall_status" == "SUCCESS" ]]; then
                        overall_status="WARNING"
                    fi
                    ;;
            esac
        else
            print_status $RED "❌ $rg: Resource group does not exist"
            overall_status="FAILED"
        fi
    done
    
    echo ""
    case "$overall_status" in
        "SUCCESS")
            print_status $GREEN "🎉 Overall Status: All deployments successful"
            ;;
        "FAILED")
            print_status $RED "💥 Overall Status: One or more deployments failed"
            ;;
        "IN_PROGRESS")
            print_status $YELLOW "⏳ Overall Status: Deployments in progress"
            ;;
        "WARNING")
            print_status $YELLOW "⚠️  Overall Status: Warnings detected"
            ;;
    esac
}

monitor_deployment_status() {
    echo "Deployment started. Monitoring progress..."
    local iteration=0
    
    while true; do
        # Clear screen and move cursor to top-left
        clear
        
        # Show header with timestamp and iteration counter
        iteration=$((iteration + 1))
        print_status $BLUE "🔄 DEPLOYMENT MONITOR - Update #$iteration"
        print_status $BLUE "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================="
        echo ""
        
        STATUS=$(az deployment sub show --name $DEPLOYMENT_NAME --query "properties.provisioningState" -o tsv)
        
        # Show main deployment status prominently
        case "$STATUS" in
            "Succeeded")
                print_status $GREEN "🎉 MAIN DEPLOYMENT STATUS: $STATUS"
                ;;
            "Failed")
                print_status $RED "❌ MAIN DEPLOYMENT STATUS: $STATUS"
                ;;
            "Running")
                print_status $YELLOW "⏳ MAIN DEPLOYMENT STATUS: $STATUS"
                ;;
            *)
                print_status $YELLOW "⚠️  MAIN DEPLOYMENT STATUS: $STATUS"
                ;;
        esac
        echo ""
        
        if [[ "$STATUS" == "Succeeded" ]]; then
            echo "Deployment completed successfully!"
            break
        elif [[ "$STATUS" == "Failed" ]]; then
            echo "Deployment failed!"
            az deployment sub show --name $DEPLOYMENT_NAME --query "properties.error" -o json
            exit 1
        fi
        
        # Construct resource group names based on the naming pattern from the Bicep template
        local shared_rg="${PROJECT_PREFIX}-${ENV_PREFIX}-shared"
        local aro_rg="${PROJECT_PREFIX}-${ENV_PREFIX}-aro"
        local jumpbox_rg="${PROJECT_PREFIX}-${ENV_PREFIX}-jumpbox"
        
        print_status $BLUE "Checking deployments for the following resource groups:"
        echo "• Shared RG: $shared_rg"
        echo "• ARO RG: $aro_rg"
        echo "• Jumpbox RG: $jumpbox_rg"
        echo "• Network RG: $NETWORK_RESOURCE_GROUP_NAME"
        echo ""
        
        # Check deployment status for each resource group
        check_deployment_status $NETWORK_RESOURCE_GROUP_NAME "Network Resources"
        check_deployment_status $shared_rg "Shared Resources"
        check_deployment_status $aro_rg "ARO Cluster"
        check_deployment_status $jumpbox_rg "Jumpbox"
        
        # Display summary
        display_summary $shared_rg $aro_rg $jumpbox_rg $NETWORK_RESOURCE_GROUP_NAME

        # Show countdown
        print_status $YELLOW "⏱️  Next update in 60 seconds... (Press Ctrl+C to stop monitoring)"
        sleep 60
    done
}