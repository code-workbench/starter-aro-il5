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

# Define resource groups to delete
RESOURCE_GROUPS=(
    "$PROJECT_PREFIX-$ENV_PREFIX-aro"
    "$PROJECT_PREFIX-$ENV_PREFIX-shared"
    "$PROJECT_PREFIX-$ENV_PREFIX-jumpbox"
    "$NETWORK_RESOURCE_GROUP_NAME"
)

# Function to check if resource group exists
check_rg_exists() {
    local rg_name=$1
    az group show --name "$rg_name" --query "name" -o tsv 2>/dev/null
}

# Function to check deletion status
check_deletion_status() {
    local rg_name=$1
    if check_rg_exists "$rg_name" > /dev/null; then
        echo "⏳ $rg_name: Still deleting..."
        return 1
    else
        echo "✅ $rg_name: Deleted successfully"
        return 0
    fi
}

# Trigger async deletions
echo "Starting async deletion of resource groups..."
for rg in "${RESOURCE_GROUPS[@]}"; do
    if check_rg_exists "$rg" > /dev/null; then
        echo "🗑️  Triggering deletion for: $rg"
        az group delete --name "$rg" --yes --no-wait
    else
        echo "ℹ️  Resource group $rg does not exist, skipping..."
    fi
done

echo ""
echo "Monitoring deletion progress..."
echo "This may take several minutes..."

# Monitor deletion status
max_attempts=60  # 30 minutes with 30-second intervals
attempt=0
all_deleted=false

while [[ $attempt -lt $max_attempts ]] && [[ $all_deleted == false ]]; do
    echo ""
    echo "Status check #$((attempt + 1)):"
    
    deleted_count=0
    for rg in "${RESOURCE_GROUPS[@]}"; do
        if check_deletion_status "$rg"; then
            ((deleted_count++))
        fi
    done
    
    if [[ $deleted_count -eq ${#RESOURCE_GROUPS[@]} ]]; then
        all_deleted=true
        echo ""
        echo "🎉 All resource groups have been deleted successfully!"
        break
    fi
    
    ((attempt++))
    if [[ $attempt -lt $max_attempts ]]; then
        echo ""
        echo "Waiting 30 seconds before next status check..."
        sleep 30
    fi
done

if [[ $all_deleted == false ]]; then
    echo ""
    echo "⚠️  Warning: Some resource groups may still be deleting after $max_attempts attempts."
    echo "Please check the Azure portal for final status."
fi