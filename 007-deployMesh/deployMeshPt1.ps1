Write-Host "Creating variables"
$resourceGroup02Name = "rg-learn-02"
$resourceGroupLocation = "uksouth"
$virtualNetwork02Name = "vnet-learn-02"
$resourceGroup03Name = "rg-learn-03"
$virtualNetwork03Name = "vnet-learn-03"
$virtualNetwork03Address = "10.3.0.0/16"
$subnet03Name = "snet-learn-03"
$subnet03NsgName = "nsg-$subnet03Name"
$subnet03Address = "10.3.1.0/24"
$virtualMachine03Name = "vm-learn-03"
$virtualMachine03NicName = "$virtualMachine03Name-nic"
$virtualMachine03DiskName = "$virtualMachine03Name-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Creating resource group: $resourceGroup03Name"
az group create `
  --name $resourceGroup03Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetwork03Name"
$virtualNetwork03Id = az network vnet create `
  --name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetwork03Address `
  --only-show-errors `
  --query newVNet.id `
  --output tsv

Write-Host "Creating network security group: $subnet03NsgName"
az network nsg create `
  --name $subnet03NsgName `
  --resource-group $resourceGroup03Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnet03Name"
az network vnet subnet create `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name $subnet03Name `
  --address-prefixes $subnet03Address `
  --network-security-group $subnet03NsgName `
  --only-show-errors `
  --output None

Write-Host "Create network interface: $virtualMachine03NicName"
az network nic create `
  --name $virtualMachine03NicName `
  --resource-group $resourceGroup03Name `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetwork03Name `
  --subnet $subnet03Name `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachine03Name"
az vm create `
  --name $virtualMachine03Name `
  --resource-group $resourceGroup03Name `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachine03DiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachine03NicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Retrieving virtual network: $virtualNetwork02Name"
$virtualNetwork02Id = az network vnet show `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Peering $virtualNetwork02Name to $virtualNetwork03Name"
az network vnet peering create `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetwork03Name `
  --remote-vnet $virtualNetwork03Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetwork03Name to $virtualNetwork02Name"
az network vnet peering create `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name peer-$virtualNetwork03Name-to-$virtualNetwork02Name `
  --remote-vnet $virtualNetwork02Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"