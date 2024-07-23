Write-Host "Creating variables"
$resourceGroupDcName = "rg-learn-dc"
$resourceGroupLocation = "uksouth"
$virtualNetworkDcName = "vnet-learn-dc"
$virtualNetworkDcAddress = "10.127.0.0/16"
$gatewaySubnetName = "GatewaySubnet"
$gatewaySubnetAddress = "10.127.0.0/24"
$subnetDcName = "snet-learn-dc"
$subnetDcNsgName = "nsg-$subnetDcName"
$subnetDcAddress = "10.127.1.0/24"
$virtualNetworkGatewayName = "gw-learn-dc"
$virtualNetworkGatewayIpName = "$virtualNetworkGatewayName-ip"
$virtualMachineDcName = "vm-learn-dc"
$virtualMachineDcNicName = "$virtualMachineDcName-nic"
$virtualMachineDcDiskName = "$virtualMachineDcName-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Creating resource group: $resourceGroupDcName"
az group create `
  --name $resourceGroupDcName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetworkDcName"
az network vnet create `
  --name $virtualNetworkDcName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetworkDcAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $gatewaySubnetName"
az network vnet subnet create `
  --vnet-name $virtualNetworkDcName `
  --resource-group $resourceGroupDcName `
  --name $gatewaySubnetName `
  --address-prefixes $gatewaySubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating network security group: $subnetDcNsgName"
az network nsg create `
  --name $subnetDcNsgName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnetDcName"
az network vnet subnet create `
  --vnet-name $virtualNetworkDcName `
  --resource-group $resourceGroupDcName `
  --name $subnetDcName `
  --address-prefixes $subnetDcAddress `
  --network-security-group $subnetDcNsgName `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $virtualNetworkGatewayIpName"
az network public-ip create `
  --name $virtualNetworkGatewayIpName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None
    
Write-Host "Creating virtual network gateway: $virtualNetworkGatewayName"
az network vnet-gateway create `
  --name $virtualNetworkGatewayName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --sku VpnGw1 `
  --gateway-type Vpn `
  --vpn-gateway-generation Generation1 `
  --vpn-type RouteBased `
  --vnet $virtualNetworkDcName `
  --public-ip-address $virtualNetworkGatewayIpName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Create network interface: $virtualMachineDcNicName"
az network nic create `
  --name $virtualMachineDcNicName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetworkDcName `
  --subnet $subnetDcName `
  --only-show-errors `
  --output None
  
Write-Host "Creating virtual machine: $virtualMachineDcName"
az vm create `
  --name $virtualMachineDcName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachineDcDiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachineDcNicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"