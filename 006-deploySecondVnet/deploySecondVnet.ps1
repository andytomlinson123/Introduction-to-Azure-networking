Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetwork01Name = "vnet-learn-01"
$subnet01Name = "snet-learn-01"
$subnet01NsgName = "nsg-$subnet01Name"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
$virtualMachine02Name = "vm-learn-02"
$virtualMachine02NicName = "$virtualMachine02Name-nic"
$virtualMachine02DiskName = "$virtualMachine02Name-disk-os"
$resourceGroup02Name = "rg-learn-02"
$virtualNetwork02Name = "vnet-learn-02"
$virtualNetwork02Address = "10.2.0.0/16"
$subnet02Name = "snet-learn-02"
$subnet02NsgName = "nsg-$subnet02Name"
$subnet02Address = "10.2.1.0/24"
$virtualMachine03Name = "vm-learn-03"
$virtualMachine03NicName = "$virtualMachine03Name-nic"
$virtualMachine03DiskName = "$virtualMachine03Name-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Deleting restrict-internet-outbound from $subnet01NsgName"
az network nsg rule delete `
  --name restrict-internet-outbound `
  --nsg-name $subnet01NsgName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting allow-internet-outbound from $subnet01NsgName"
az network nsg rule delete `
  --name allow-internet-outbound `
  --nsg-name $subnet01NsgName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting deny-internet-outbound from $subnet01NsgName"
az network nsg rule delete `
  --name deny-internet-outbound `
  --nsg-name $subnet01NsgName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Disassociating application security groups: $virtualMachine01NicName"
az network nic ip-config update `
  --name ipconfig1 `
  --nic-name $virtualMachine01NicName `
  --resource-group $resourceGroup01Name `
  --remove application_security_groups `
  --only-show-errors `
  --output None
  
Write-Host "Deleting virtual machine: $virtualMachine02Name"
az vm delete `
  --name $virtualMachine02Name `
  --resource-group $resourceGroup01Name `
  --yes `
  --only-show-errors `
  --output None

Write-Host "Deleting network interface: $virtualMachine02NicName"
az network nic delete `
  --name $virtualMachine02NicName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting disk: $virtualMachine02DiskName"
az disk delete `
  --disk-name $virtualMachine02DiskName `
  --resource-group $resourceGroup01Name `
  --yes `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deleting virtual machine: $virtualMachine03Name"
az vm delete `
  --name $virtualMachine03Name `
  --resource-group $resourceGroup01Name `
  --yes `
  --only-show-errors `
  --output None
  
Write-Host "Deleting network interface: $virtualMachine03NicName"
az network nic delete `
  --name $virtualMachine03NicName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None
  
Write-Host "Deleting disk: $virtualMachine03DiskName"
az disk delete `
  --disk-name $virtualMachine03DiskName `
  --resource-group $resourceGroup01Name `
  --yes `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deleting subnet: $subnet02Name"
az network vnet subnet delete `
  --name $subnet02Name `
  --resource-group $resourceGroup01Name `
  --vnet-name $virtualNetwork01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting network security group: $subnet02NsgName"
az network nsg delete `
  --name $subnet02NsgName `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deleting application security group: asg-restrict-internet"  
az network asg delete `
  --name asg-restrict-internet `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None
  
Write-Host "Deleting application security group: asg-allow-internet"  
az network asg delete `
  --name asg-allow-internet `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deleting application security group: asg-restrict-snet-learn-02"  
az network asg delete `
  --name asg-restrict-snet-learn-02 `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None
  
Write-Host "Deleting application security group: asg-allow-snet-learn-02"  
az network asg delete `
  --name asg-allow-snet-learn-02 `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Creating resource group: $resourceGroup02Name"
az group create `
  --name $resourceGroup02Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetwork02Name"
$virtualNetwork02Id = az network vnet create `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetwork02Address `
  --query newVNet.id `
  --only-show-errors `
  --output tsv

Write-Host "Creating network security group: $subnet02NsgName"
az network nsg create `
  --name $subnet02NsgName `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnet02Name"
az network vnet subnet create `
  --name $subnet02Name `
  --resource-group $resourceGroup02Name `
  --vnet-name $virtualNetwork02Name `
  --address-prefixes $subnet02Address `
  --network-security-group $subnet02NsgName `
  --only-show-errors `
  --output None

Write-Host "Create network interface: $virtualMachine02NicName"
az network nic create `
  --name $virtualMachine02NicName `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetwork02Name `
  --subnet $subnet02Name `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachine02Name"
az vm create `
  --name $virtualMachine02Name `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachine02DiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachine02NicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Retrieving virtual network: $virtualNetwork01Name"
$virtualNetwork01Id = az network vnet show `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --query id `
  --only-show-errors `
  --output tsv

Write-Host "Peering $virtualNetwork01Name to $virtualNetwork02Name"
az network vnet peering create `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetwork02Name `
  --remote-vnet $virtualNetwork02Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetwork02Name to $virtualNetwork01Name"
az network vnet peering create `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetwork01Name `
  --remote-vnet $virtualNetwork01Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"
