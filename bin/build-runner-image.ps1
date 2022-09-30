
param (
	[Parameter(Mandatory = $true)][string]$resourceGroup,
	[Parameter(Mandatory = $true)][string]$location,
	[Parameter(Mandatory = $true)][string]$subscriptionId,
	[Parameter(Mandatory = $true)][ValidateSet("Windows2019", "Windows2022", "Ubuntu1804", "Ubuntu2004", "Ubuntu2204")][string]$imageType,
	[Parameter(Mandatory = $true)][string]$azureClientId, 
	[Parameter(Mandatory = $true)][string]$azureClientSecret,
	[Parameter(Mandatory = $true)][string]$azureTenantId
)

Write-Host "Installing Az module"
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
Uninstall-AzureRm

Write-Host "Cloning runner-images GitHub repository"

Set-Location C:\
git clone https://github.com/actions/runner-images.git

Write-Host "Repository cloned"
Set-Location C:\runner-images

Write-Host "Importing module GenerateResourcesAndImage"
Import-Module .\helpers\GenerateResourcesAndImage.ps1

Write-Host "Calling GenerateResourcesAndImage script"
GenerateResourcesAndImage `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $resourceGroup `
	-ImageGenerationRepositoryRoot "$pwd" `
	-ImageType $imageType `
	-AzureLocation $location `
	-AzureClientId $azureClientId `
	-AzureClientSecret "$azureClientSecret" `
	-AzureTenantId $azureTenantId