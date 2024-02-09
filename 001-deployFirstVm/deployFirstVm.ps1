Write-Host "Creating variables"
$resourceGroupName = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetworkName = "vnet-learn-01"
$virtualNetworkAddress = "10.1.0.0/16"
$subnetName = "snet-learn-01"
$subnetAddress = "10.1.1.0/24"
$virtualMachineName = "vm-learn-01"
$virtualMachineNsgName = "$virtualMachineName-nsg"
$virtualMachineIpName = "$virtualMachineName-ip"
$virtualMachineNicName = "$virtualMachineName-nic"
$virtualMachineDiskName = "$virtualMachineName-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Creating resource group: $resourceGroupName"
az group create `
  --name $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetworkName"
az network vnet create `
  --name $virtualNetworkName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetworkAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnetName"
az network vnet subnet create `
  --vnet-name $virtualNetworkName `
  --resource-group $resourceGroupName `
  --name $subnetName `
  --address-prefixes $subnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating network security group: $virtualMachineNsgName"
az network nsg create `
  --name $virtualMachineNsgName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Retrieving your public IP address"
$yourPublicIp = Invoke-WebRequest -Uri https://ipinfo.io | ConvertFrom-Json

Write-Host "Creating security rule: allow-ssh-inbound"
az network nsg rule create `
  --nsg-name $virtualMachineNsgName `
  --resource-group $resourceGroupName `
  --name allow-ssh-inbound `
  --direction Inbound `
  --priority 100 `
  --access Allow `
  --source-address-prefixes $yourPublicIp.ip `
  --destination-address-prefixes "*" `
  --protocol TCP `
  --destination-port-ranges 22 `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $virtualMachineIpName"
az network public-ip create `
  --name $virtualMachineIpName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating network interface: $virtualMachineNicName"
az network nic create `
  --name $virtualMachineNicName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetworkName `
  --subnet $subnetName `
  --network-security-group $virtualMachineNsgName `
  --public-ip-address $virtualMachineIpName `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachineName"
az vm create `
  --name $virtualMachineName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachineDiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachineNicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"