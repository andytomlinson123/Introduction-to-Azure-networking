Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetwork01Name = "vnet-learn-01"
$bastionSubnetName = "AzureBastionSubnet"
$bastionName = "bas-learn-01"
$bastionIpName = "$bastionName-ip"
$resourceGroup02Name = "rg-learn-02"
$virtualNetwork02Name = "vnet-learn-02"
$resourceGroup03Name = "rg-learn-03"
$virtualNetwork03Name = "vnet-learn-03"
$resourceGroupHubName = "rg-learn-hub"
$virtualNetworkHubName = "vnet-learn-hub"
$virtualNetworkHubAddress = "10.0.0.0/16"
$gatewaySubnetName = "GatewaySubnet"
$gatewaySubnetAddress = "10.0.0.0/24"
$bastionSubnetAddress = "10.0.1.0/24"
$virtualNetworkGatewayName = "gw-learn-hub"
$virtualNetworkGatewayIpName = "$virtualNetworkGatewayName-ip"
$bastionHubName = "bas-learn-hub"
$bastionHubIpName = "$bastionHubName-ip"

Write-Host "Deleting peer: peer-$virtualNetwork01Name-to-$virtualNetwork02Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetwork02Name `
  --only-show-errors `
  --output None

Write-Host "Deleting peer: peer-$virtualNetwork01Name-to-$virtualNetwork03Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetwork03Name `
  --only-show-errors `
  --output None

Write-Host "Deleting peer: peer-$virtualNetwork02Name-to-$virtualNetwork01Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetwork01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting peer: peer-$virtualNetwork02Name-to-$virtualNetwork03Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetwork03Name `
  --only-show-errors `
  --output None

Write-Host "Deleting peer: peer-$virtualNetwork03Name-to-$virtualNetwork02Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name peer-$virtualNetwork03Name-to-$virtualNetwork02Name `
  --only-show-errors `
  --output None

Write-Host "Deleting peer: peer-$virtualNetwork03Name-to-$virtualNetwork01Name"
az network vnet peering delete `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name peer-$virtualNetwork03Name-to-$virtualNetwork01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting Bastion: $bastionName"
az network bastion delete `
  --name $bastionName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting public IP address: $bastionIpName"
az network public-ip delete `
  --name $bastionIpName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None

Write-Host "Deleting subnet: $bastionSubnetName"
az network vnet subnet delete `
  --name $bastionSubnetName `
  --resource-group $resourceGroup01Name `
  --vnet-name $virtualNetwork01Name `
  --only-show-errors `
  --output None

Write-Host "Creating resource group: $resourceGroupHubName"
az group create `
  --name $resourceGroupHubName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetworkHubName"
az network vnet create `
  --name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetworkHubAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $gatewaySubnetName"
az network vnet subnet create `
  --name $gatewaySubnetName `
  --resource-group $resourceGroupHubName `
  --vnet-name $virtualNetworkHubName `
  --address-prefixes $gatewaySubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $bastionSubnetName"
az network vnet subnet create `
  --name $bastionSubnetName `
  --resource-group $resourceGroupHubName `
  --vnet-name $virtualNetworkHubName `
  --address-prefixes $bastionSubnetAddress `
  --only-show-errors `
  --output None
  
Write-Host "Creating public IP address: $virtualNetworkGatewayIpName"
az network public-ip create `
  --name $virtualNetworkGatewayIpName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network gateway: $virtualNetworkGatewayName"
az network vnet-gateway create `
  --name $virtualNetworkGatewayName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku VpnGw1 `
  --gateway-type Vpn `
  --vpn-gateway-generation Generation1 `
  --vpn-type RouteBased `
  --vnet $virtualNetworkHubName `
  --public-ip-address $virtualNetworkGatewayIpName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $bastionHubIpName"
az network public-ip create `
  --name $bastionHubIpName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating Bastion: $bastionHubName"
az network bastion create `
  --name $bastionHubName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Standard `
  --vnet-name $virtualNetworkHubName `
  --public-ip-address $bastionHubIpName `
  --enable-tunneling `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"