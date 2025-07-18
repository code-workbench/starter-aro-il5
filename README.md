# Starter Azure RedHat OpenShift for IL5
Infrastructure-as-Code template for Deploying Azure RedHat OpenShift in an IL5 environment.  The goal being to provide a starter template for getting an environment created and providing all the baseline controls.  Note:  This template implements the controls found in the Azure IL5 documentation found [here](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-impact-level-5).  And would need to be validated by appropriate parties.  

# What is included in this template?

This template includes the following infrastructure components:

```mermaid
graph TB
    subgraph "Subscription"
        NET_RG[Network Resource Group]
        SHARED_RG["Shared Resource Group<br>(project-env-shared)"]
        ARO_RG["ARO Resource Group<br>(project-env-aro)"]
        JB_RG["Jumpbox Resource Group<br>(project-env-jumpbox)"]
        
        subgraph NET_RG
            VNET["Virtual Network<br>(Existing)"]
            
            subgraph "Subnets"
                CP_SUB["Control Plane Subnet<br>(10.0.64.0/18)"]
                W_SUB["Worker Subnet<br>(10.0.128.0/18)"]
                REG_SUB["Registry Subnet<br>(10.0.192.0/18)"]
                KV_SUB["Key Vault Subnet<br>(10.1.0.0/18)"]
                STG_SUB["Storage Subnet<br>(10.1.64.0/18)"]
                JB_SUB["Jumpbox Subnet<br>(10.1.128.0/18)"]
                BST_SUB["Bastion Subnet<br>(10.1.192.0/18)"]
            end
        end
        
        subgraph SHARED_RG
            KV["Key Vault<br>(with CMK)"]
            ACR["Container Registry<br>(Premium)"]
            STG["Storage Account"]
            
            MI_STG["Storage Managed Identity"]
            MI_REG["Registry Managed Identity"]
            
            KV --> MI_STG
            KV --> MI_REG
            ACR --> MI_REG
            STG --> MI_STG
        end
        
        subgraph ARO_RG
            ARO["Azure RedHat OpenShift Cluster"]
        end
        
        subgraph JB_RG
            JB["Jumpbox VM<br>(Optional)"]
            BASTION["Azure Bastion"]
        end
        
        %% Connections
        CP_SUB --> ARO
        W_SUB --> ARO
        REG_SUB --> ACR
        KV_SUB --> KV
        STG_SUB --> STG
        JB_SUB --> JB
        BST_SUB --> BASTION
        BASTION --> JB
    end
```

This repo is designed to be deployed to an existing virtual network, and will modify the network to support the required subnets.  

# Installing Azure CLI

To manage your Azure resources, you need to install the Azure CLI. Follow the instructions below to download and install it on your system.

## Windows

1. Download the Azure CLI installer from the following link: [Azure CLI Installer](https://aka.ms/installazurecliwindows).
2. Run the installer and follow the on-screen instructions.

## macOS

1. Open your terminal.
2. Run the following command to install Azure CLI using Homebrew:
    ```bash
    brew update && brew install azure-cli
    ```

## Linux

1. Open your terminal.
2. Run the following commands to install Azure CLI using the package manager for your distribution:

    **Debian/Ubuntu:**
    ```bash
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    ```

    **RHEL/CentOS:**
    ```bash
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[azure-cli]
    name=Azure CLI
    baseurl=https://packages.microsoft.com/yumrepos/azure-cli
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
    sudo yum install azure-cli
    ```

    **Fedora:**
    ```bash
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y https://packages.microsoft.com/yumrepos/azure-cli/azure-cli-2.0.81-1.el7.x86_64.rpm
    ```

    **openSUSE:**
    ```bash
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper addrepo --name 'Azure CLI' --check https://packages.microsoft.com/yumrepos/azure-cli azure-cli
    sudo zypper install --from azure-cli -y azure-cli
    ```

After installation, you can verify the installation by running:

```bash
az --version
```

# Logging into Azure

The following steps will make it possible to deploy with a brand new network:
For deploying to Azure Government run the following:

```bash
az cloud set --name AzureUSGovernment
```

The following is the command to login.  

```bash
az login
```

or if you need to open the window on another machine (linux for example):

```bash
az login --use-device-code
```

# OPTIONAL - Create a vm image for a kubernetes jumpbox

As part of this repo, there is a packer script for creating a jumpbox on ubuntu 22.04-LTS that has several common tools for working with Kubernetes enabled.  The file can be found:

- **[kubernetes-linux-jumpbox.pkr.hcl](./custom-images/kubernetes-linux-jumpbox.pkr.hcl): This machine provides a jumpbox for accessing and working with kubernetes clusters.  

If you wish to build the image, the following steps can be used.

## Build packer vm images:

To build a VM image in your Azure subscription using the `./custom-images/kubernetes-linux-jumpbox.pkr.hcl` file, follow these steps:

1. **Install Packer**  
  Make sure you have [Packer](https://developer.hashicorp.com/packer/install) installed on your machine. You can run this script to install it or use the repo task by hitting F1.

  ```bash
  bash ./scripts/install-packer.sh
  ```

2. **Authenticate with Azure**  
  Ensure you are logged in to Azure CLI and have the necessary permissions:
  ```bash
  az cloud set --name AzureUSGovernment
  az login --use-device-code
  az account set --subscription "<your-subscription-id>"
  ```

**NOTE: There is a task in this repo that can be executed to perform this build using values in the environment.json file**

3. **Run Packer init**
  Run the following command to validate your Packer template:
  ```bash
  packer init ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
  ```

3. **Validate the Packer Template**  
  Run the following command to validate your Packer template:
  ```bash
  packer validate ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
  ```

4. **Build the Image**  
  Execute the build command:
  ```bash
  packer build -var "subscription_id=<your-subscription-id>" -var "location=<your-location>" ./custom-images/kubernetes-linux-jumpbox.pkr.hcl
  ```

5. **Locate the Image in Azure**  
  After the build completes, the image will be available in the resource group and location specified in your Packer template.

> For more details, see the [Packer Azure Builder documentation](https://developer.hashicorp.com/packer/plugins/builders/azure).

You will need to get the "ManagedImageId" for the newly created image if you want to use it in the deployment.  

# Pre-requisites

The following are pre-reqs for using this repo.

## Creating Environment JSON:

For this implementation, you need to create an environment json, there is a sample in the repo under the '''./envs/sample.json'''.

You can create a new file using the following command:

```
ENV_FILE_NAME="" # Name of the file
cp ./envs/sample.json "./envs/$ENV_FILE_NAME"
```

You will then need to populate the following parameters:

## Setting Configuration Parameters:

Below is an example configuration that you can use to populate your environment JSON file:

```json
{
    "networkResourceGroupName": "starter-aro-il5",
    "vnetName": "starter-aro-il5-vnet",
    "location": "usgovvirginia",
    "subnetName": "default",
    "projectPrefix": "aro1",
    "envPrefix": "dev",
    "defaultTagName": "Environment",
    "defaultTagValue": "dev",
    "servicePrincipalClientId": "",
    "servicePrincipalClientSecret": "",
    "subscriptionId":"",
    "deployJumpBox": false,
    "jumpboxUsername": "",
    "jumpboxPassword": "",
    "custom_managed_image_id": ""
}
```

The values are:
**resourceGroupName:** The resource group to deploy to.
**vnetName:** The name of the virtual network to connect to.  
**location:** The region to deploy to.
**subnetName:** The name of the default subnet to make sure that the newly created vnet has.  *Only required if you are creating a new virtual network as a starting point.*
**projectPrefix:** A prefix to denote as part of the naming convention. 
**envPrefix:** A prefix identifying the environment being deployed.  
**defaultTagName:** A default tag to put on the environment. 
**defaultTagValue:** The value of the tag to be applied to all resources on the environment. 
**servicePrincipalClientId:** The Client ID of the Service Principal required for ARO.
**servicePrincipalClientSecret:** The Client Secret of the Service Principal required for ARO.  
**subscriptionId:** The subscription id being deployed to.
**deployJumpBox:** True / False for deploying a jumpbox with bastion.
**jumpboxUsername:** The username for accessing the jumpbox.  
**jumpboxPassword:** The password for accessing the jumpbox.  
**custom_managed_image_id:** Can be updated to point a custom image for the jumpbox.  

Make sure to replace the `servicePrincipalClientId` and `servicePrincipalClientSecret` with the values from your created service principal.

## Creating Service Principal:

For this template, you will need to provide a service principal.

You can generate it with the following command:

```bash
# The name of the resource group
SP_NAME=""

az ad sp create-for-rbac --name "sp-$SP_NAME-${RANDOM}" > app-service-principal.json
SP_CLIENT_ID=$(jq -r '.appId' app-service-principal.json)
SP_CLIENT_SECRET=$(jq -r '.password' app-service-principal.json)
SP_OBJECT_ID=$(az ad sp show --id $SP_CLIENT_ID | jq -r '.id')
```

**NOTE: The Service Principal will need "Network Contributor" role on the virtual network being leveraged.**

This can be assigned with the following:

```bash
SERVICE_PRINCIPAL_CLIENT_ID="" # The client id
VNET_RESOURCE_ID="" # The resource id of the virtual network.
az role assignment create --assignee $SERVICE_PRINCIPAL_CLIENT_ID --role "Network Contributor" --scope $VNET_RESOURCE_ID
```

## Update Reference

To make all tasks point to your configuration, you can update the ENV_FILE found [here](./scripts/common.sh).

# Network Considerations:

The following are key network considerations for deploying Azure RedHat OpenShift.  

1. You must have a big enough cidr block.  ARO requires that the pod cidr supports a /18.  
1. Granting "Network Contributor" rights to your virtual network for the "Azure RedHat OpenShift Resource Provider", more can be found [here](https://learn.microsoft.com/en-us/answers/questions/1687840/whats-the-purpose-and-role-of-azure-red-hat-opensh).

# Deploy this template

For this, we have 3 options for deploying this template:

1. Deploy using vscode tasks
1. Deploy manually

**NOTE: This deployment can take around 60 minutes to deploy into your environment.**

## Deploy using vscode tasks

For this project, we have implemented vscode tasks for common operations to make it easier to use.  These include the following:

- **Az Login:** Performs an azure cli login.  
- **Delete Resource Group:** Will leverage Azure CLI to delete the resource group that is being used to deploy this template.  
- **Create RG and Vnet:** Will leverage Azure CLI to create a resource group and landing vnet for this solution.  
- **Deploy Template:** Will leverage Azure CLI to deploy the bicep template. 

To run this tasks, you can click "F1" or "Ctrl+Shift+P" or go to "Terminal" => "Run Task".

The following menu will appear:
![Open the command palette and select run task](./images/run-task.png)

And then select your task:
![Choose a task from the list below](./images/select-tasks.png)

## Deploy template manually

You can leverage the following to deploy this template to your environment:

**NOTE: This requires the an existing virtual network to deploy.  To Create one, use the following:**

```bash
bash ./scripts/create-rg-vnet.sh
```

**NOTE: You will need to give your service principal and the "Azure Open Shift RP" service principal "Network Contributor" rights.**

```bash
bash ./scripts/deploy-template.sh
```

# Delete Infrastructure

If you need to clean up the infrastructure, you can do so by running the following:

```bash
bash ./scripts/delete-rg.sh
```