
# Using managed images in VM Scale Sets for DevOps

## Prerequisites

Following are prerequisites for using managed images in VM scale sets:

1. Create VHD disk image from https://github.com/actions/runner-images following [instructions](https://github.com/actions/runner-images/blob/main/docs/create-image-and-azure-resources.md). 

> NOTE: This step may take 6 hours.
2. After sucesfully creating VHD file, follow [installation instructions](#installation) bellow.


## Installation

## 1. Create Image gallery 

Create an image gallery for storing images for VM.

```bash
az sig create \
  --resource-group devops-runner-images-04-rg \
  --gallery-name mngImages01
```

## 2. Create image definition

Create image definition (e.g. _Windows 2022_, _Ubuntu_, etc.)

```bash
az sig image-definition create \
  --resource-group devops-runner-images-04-rg \
  --gallery-name mngImages01 \
  --gallery-image-definition Windows2022 \
  --publisher CustomBuild \
  --offer myOffer \
  --sku mySKU \
  --os-type Windows \
  --os-state generalized
```
 
## 3. Create image version

Create a new version of image (using previously generated VHD file).

```bash
az sig image-version create \
  --resource-group devops-runner-images-04-rg \
  --gallery-name mngImages01 \
  --gallery-image-definition Windows2022 \
  --gallery-image-version 1.0.0 \
  --os-vhd-storage-account /subscriptions/<subscriptionId>/resourceGroups/imageGroups/providers/Microsoft.Storage/storageAccounts/devopsrunnerimages04001 \
  --os-vhd-uri https://devopsrunnerimages04001.blob.core.windows.net/system/Microsoft.Compute/Images/images/packer-osDisk.vhd
```
> NOTE: This step may take 30 minutes

## 4. Create VM Scale Set

First create a VM Scale Set:

```bash
az vmss create \
  --name devops-vmss-pool-01 \
  --resource-group devops-runner-images-04-rg \
  --image /subscriptions/<subscriptionId>/resourceGroups/devops-runner-images-04-rg/providers/Microsoft.Compute/galleries/mngImages01/images/Windows2022/versions/1.0.0 \
  --vm-sku Standard_D2_v3 \
  --storage-sku StandardSSD_LRS \
  --instance-count 2 \
  --disable-overprovision \
  --upgrade-policy-mode manual \
  --single-placement-group false \
  --platform-fault-domain-count 1 \
  --admin-user azureuser
  --load-balancer ""
```

> IMPORTANT: If you run this script using Azure CLI on Windows, you must enclose the "" in --load-balancer "" with single quotes like this: --load-balancer '""'

Afterwards configure createing new [Scale Set Agent Pool in DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops).

## License

Lincensed under [MIT](LICENSE.md) license.