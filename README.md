# Starter Azure RedHat OpenShift for IL5
Infrastructure-as-Code template for Deploying Azure RedHat OpenShift in an IL5 environment.  The goal being to provide a starter template for getting an environment created and providing all the baseline controls.  

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

# Deploy the template

You can leverage the following to deploy this template to your environment:

**NOTE: This requires the an existing virtual network to deploy.  To Create one, use the following:**

```
RESOURCE_GROUP_NAME="starter-aro-il5"
VNET_NAME="starter-aro-il5-vnet"
LOCATION="usgovvirginia"
SUBNET_NAME="default"

# Create the resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create the virtual network
az network vnet create --name $VNET_NAME --resource-group $RESOURCE_GROUP_NAME --subnet-name $SUBNET_NAME
```

```
PROJECT_PREFIX="aroil5"
ENV_PREFIX="dev"
DEFAULT_TAG_NAME="Environment"
DEFAULT_TAG_VALUE="aro-il5"

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ./main.bicep --parameters project_prefix=$PROJECT_PREFIX env_prefix=$ENV_PREFIX location=$LOCATION existing_network_name=$VNET_NAME default_tag_name=$DEFAULT_TAG_NAME default_tag_value=$DEFAULT_TAG_VALUE
```
