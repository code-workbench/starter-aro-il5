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

# Function to clear lines and move cursor up
clear_status_display() {
    local lines_to_clear=$1
    for ((i=0; i<lines_to_clear; i++)); do
        echo -ne "\033[2K\033[1A"  # Clear line and move up
    done
}

# Function to display current status
display_status() {
    local attempt=$1
    local max_attempts=$2
    local deleted_count=0
    
    echo "Status check #$((attempt + 1))/$max_attempts:"
    
    for rg in "${RESOURCE_GROUPS[@]}"; do
        if check_rg_exists "$rg" > /dev/null; then
            echo "⏳ $rg: Still deleting..."
        else
            echo "✅ $rg: Deleted successfully"
            ((deleted_count++))
        fi
    done
    
    echo "Progress: $deleted_count/${#RESOURCE_GROUPS[@]} completed"
    
    if [[ $deleted_count -lt ${#RESOURCE_GROUPS[@]} ]]; then
        echo "Next check in 30 seconds..."
    fi
    
    return $deleted_count
}

# Monitor deletion status
max_attempts=60  # 30 minutes with 30-second intervals
attempt=0
all_deleted=false
status_lines=$((${#RESOURCE_GROUPS[@]} + 3))  # RGs + header + progress + next check

echo ""  # Add initial spacing

while [[ $attempt -lt $max_attempts ]] && [[ $all_deleted == false ]]; do
    # Clear previous status display (except on first iteration)
    if [[ $attempt -gt 0 ]]; then
        clear_status_display $status_lines
    fi
    
    display_status $((attempt + 1)) $max_attempts
    deleted_count=$?
    
    if [[ $deleted_count -eq ${#RESOURCE_GROUPS[@]} ]]; then
        all_deleted=true
        clear_status_display $status_lines
        echo "🎉 All resource groups have been deleted successfully!"
        break
    fi
    
    ((attempt++))
    if [[ $attempt -lt $max_attempts ]]; then
        sleep 30
    fi
done

if [[ $all_deleted == false ]]; then
    echo ""
    echo "⚠️  Warning: Some resource groups may still be deleting after $max_attempts attempts."
    echo "Please check the Azure portal for final status."
fi