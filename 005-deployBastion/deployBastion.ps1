Write-Host "Creating variables"
$resourceGroupName = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$natGwName = "natgw-learn-01"
$natGwIpName = "$natGwName-ip"
$virtualNetworkName = "vnet-learn-01"
$subnet01Name = "snet-learn-01"
$subnet01NsgName = "nsg-$subnet01Name"
$subnet02Name = "snet-learn-02"
$bastionSubnetName = "AzureBastionSubnet"
$bastionSubnetAddress = "10.1.255.0/24"
$bastionName = "bas-learn-01"
$bastionIpName = "$bastionName-ip"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01IpName = "$virtualMachine01Name-ip"
$virtualMachine01NicName = "$virtualMachine01Name-nic"

Write-Host "Disassociating $natGwName from $subnet01Name"
az network vnet subnet update `
  --vnet-name $virtualNetworkName `
  --name $subnet01Name `
  --resource-group $resourceGroupName `
  --remove nat_gateway `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Disassociating $natGwName from $subnet02Name"
az network vnet subnet update `
  --vnet-name $virtualNetworkName `
  --name $subnet02Name `
  --resource-group $resourceGroupName `
  --remove nat_gateway `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deleting NAT gateway: $natGwName"
az network nat gateway delete `
  --name $natGwName `
  --resource-group $resourceGroupName `
  --only-show-errors `
  --output None

Write-Host "Deleting public IP address: $natGwIpName"
az network public-ip delete `
  --name $natGwIpName `
  --resource-group $resourceGroupName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $bastionSubnetName"
az network vnet subnet create `
  --name $bastionSubnetName `
  --resource-group $resourceGroupName `
  --vnet-name $virtualNetworkName `
  --address-prefixes $bastionSubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $bastionIpName"
az network public-ip create `
  --name $bastionIpName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating Bastion: $bastionName"
az network bastion create `
  --name $bastionName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --sku Standard `
  --vnet-name $virtualNetworkName `
  --public-ip-address $bastionIpName `
  --enable-tunneling `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Disassociating $virtualMachine01IpName from $virtualMachine01NicName"
az network nic ip-config update `
  --name ipconfig1 `
  --nic-name $virtualMachine01NicName `
  --resource-group $resourceGroupName `
  --remove public_ip_address `
  --only-show-errors `
  --output None

Write-Host "Deleting $virtualMachine01IpName"
az network public-ip delete `
  --name $virtualMachine01IpName `
  --resource-group $resourceGroupName `
  --only-show-errors `
  --output None

Write-Host "Deleting allow-ssh-inbound from $subnet01NsgName"
az network nsg rule delete `
  --nsg-name $subnet01NsgName `
  --resource-group $resourceGroupName `
  --name allow-ssh-inbound `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"