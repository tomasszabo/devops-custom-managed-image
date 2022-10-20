
# Using managed images in VM Scale Sets for DevOps - building locally

## 1. Create VHD

VHD is created from [runner-images GitHub repository](https://github.com/actions/runner-images) using their [instructions](https://github.com/actions/runner-images/blob/main/docs/create-image-and-azure-resources.md). Following is a quick overview of steps needed to build VHD:

1. Clone [runner-images GitHub repository](https://github.com/actions/runner-images).
2. Install [prerequisites](https://github.com/actions/runner-images/blob/main/docs/create-image-and-azure-resources.md#prepare-environment-and-image-deployment).
3. Start PowerShell in cloned directory
4. Import module `GenerateResourcesAndImage`
```PowerShell
Import-Module .\helpers\GenerateResourcesAndImage.ps1    
```
5. Generate VHD
```PowerShell
GenerateResourcesAndImage -SubscriptionId {subscription-id} -ResourceGroupName {resource-group-name} -ImageGenerationRepositoryRoot "$pwd" -ImageType {one of available images, e.g. Windows2022, UbuntuLatest, etc.} -AzureLocation "WestEurope"
```

List of available images is [here](https://github.com/actions/runner-images#available-images). Full instructions with options can be found in [runner-images instructions](https://github.com/actions/runner-images/blob/main/docs/create-image-and-azure-resources.md). 

> NOTE: This step may take 6 or more hours.

## 2. Create Image gallery 

Create an image gallery for storing images for virtual machines in VM Scale Set:

```bash
az sig create \
  --resource-group {resource-group-name} \
  --gallery-name ImagesGallery01
```

## 3. Create image definition

Create image definition (e.g. _Windows2022_, _Ubuntu_, etc.):

```bash
az sig image-definition create \
  --resource-group {resource-group-name} \
  --gallery-name ImagesGallery01 \
  --gallery-image-definition windows2022 \
  --publisher myCustomBuild \
  --offer myOffer \
  --sku mySKU \
  --os-type Windows \
  --os-state generalized
```
Parameter `gallery-image-definition` doesn't refer to anything, it's just a name for image in your image gallery. 
 
## 4. Create image version from VHD

Create a new version of image (using previously generated VHD file):

```bash
az sig image-version create \
  --resource-group {resource-group-name} \
  --gallery-name ImagesGallery01 \
  --gallery-image-definition Windows2022 \
  --gallery-image-version 1.0.0 \
  --os-vhd-storage-account /subscriptions/{subscription-id}/resourceGroups/imageGroups/providers/Microsoft.Storage/storageAccounts/{storage-account-name-from-step-1} \
  --os-vhd-uri {URL of packer-osDisk.vhd from storage account, e.g. https://devopsrunnerimagesxyz.blob.core.windows.net/system/Microsoft.Compute/Images/images/packer-osDisk.vhd}
```
> NOTE: This step may take 30 or more minutes

Use parameter `gallery-image-version` to distinguish between versions of this image, e.g. _1.0.0_, _v2_, _2022-09-12_, _2022-10-05_, etc.

## 5. Create VM Scale Set

First create a VM Scale Set using previously created image:

```bash
az vmss create \
  --name devops-vmss-pool-01 \
  --resource-group {resource-group-name} \
  --image /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.Compute/galleries/ImagesGallery01/images/Windows2022/versions/latest \
  --vm-sku Standard_D2_v3 \
  --storage-sku StandardSSD_LRS \
  --instance-count 2 \
  --disable-overprovision \
  --upgrade-policy-mode manual \
  --single-placement-group false \
  --platform-fault-domain-count 1 \
  --admin-user azureuser \
  --load-balancer ""
```

> IMPORTANT: If you run this script using Azure CLI on Windows, you must enclose the "" in --load-balancer "" with single quotes like this: --load-balancer '""'

Afterwards configure creating new [VM Scale Set Agent Pool in DevOps](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops).
