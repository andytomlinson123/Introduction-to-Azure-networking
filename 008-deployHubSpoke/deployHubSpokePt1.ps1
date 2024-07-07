Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetwork01Name = "vnet-learn-01"
$bastionSubnetName = "AzureBastionSubnet"
$bastionName = "bas-learn-01"
$bastionIpName = "$bastionName-ip"
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

Write-Host "Retrieving virtual networks"
$virtualNetworks = az network vnet list `
  --only-show-errors `
  --output json | ConvertFrom-Json

foreach ($virtualNetwork in $virtualNetworks) {

  $virtualNetworkPeerings = $virtualNetwork.virtualNetworkPeerings

  foreach ($virtualNetworkPeering in $virtualNetworkPeerings) {

    $virtualNetworkPeeringName = $virtualNetworkPeering.name
    $virtualNetworkPeeringId = $virtualNetworkPeering.id

    Write-Host "Deleting peer: $($virtualNetworkPeeringName)"
    az network vnet peering delete `
      --ids $virtualNetworkPeeringId `
      --only-show-errors `
      --output None
  }
}

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
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name $bastionSubnetName `
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
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name $gatewaySubnetName `
  --address-prefixes $gatewaySubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $bastionSubnetName"
az network vnet subnet create `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name $bastionSubnetName `
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