# !/bin/bash
# This script creates a resource group and a virtual network in Azure.
# It requires the Azure CLI to be installed and configured.

source "$(dirname "$0")/common.sh"

check_jq_installed

if ! command -v packer &> /dev/null; then
    echo "Packer is not installed. Installing Packer..."
    ./scripts/install-packer.sh
fi

if [[ "$#" -eq 0 ]]; then
    load_parameters
else
    parse_passed_parameters "$@"
fi

echo "Building image..."

START_TIME=$(date +%s)

echo "Initializing Packer..."
packer init ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
if [[ $? -ne 0 ]]; then
    echo "Packer initialization failed. Exiting."
    exit 1
else 
    echo "Packer initialized successfully."
fi

echo "Validating Packer template..."
packer validate ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
if [[ $? -ne 0 ]]; then
    echo "Packer template validation failed. Exiting."
    exit 1
else 
    echo "Packer template validated successfully."
fi

echo "Building Packer image..."
packer build -var "subscription_id=$SUBSCRIPTION_ID" -var "location=$LOCATION" -force ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
if [[ $? -ne 0 ]]; then
    echo "Packer image build failed. Exiting."
    exit 1
else 
    echo "Packer image built successfully."
fi

END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

if [[ $? -eq 0 ]]; then
    echo "Image Built successfully. Execution time - ${MINUTES}:${SECONDS}"
else
    echo "Image Build failed. Execution time - ${MINUTES}:${SECONDS}" >&2
fi