Write-Host "Creating variables"
$resourceGroupHubName = "rg-learn-hub"
$resourceGroupLocation = "uksouth"
$virtualNetworkHubName = "vnet-learn-hub"
$gatewaySubnetName = "GatewaySubnet"
$gatewaySubnetRtName = "rt-$gatewaySubnetName"
$firewallName = "fw-learn-hub"

Write-Host "Retrieving private IP address: $firewallName"
$firewallPrivateIp = az network firewall show `
  --name $firewallName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --query ipConfigurations[0].privateIPAddress `
  --output tsv

Write-Host "Retrieving peerings: $VirtualNetworkHubName"
$hubPeerings = az network vnet peering list `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --output json | ConvertFrom-Json

foreach ($hubPeering in $hubPeerings) {

  $hubPeeringName = $hubPeering.name
  $hubPeeringId = $hubPeering.id

  Write-Host "Deleting allow gateway transit: $hubPeeringName"
  az network vnet peering update `
    --ids $hubPeeringId `
    --remove allow_gateway_transit `
    --only-show-errors `
    --output None
}
  
Write-Host "Creating route table: $gatewaySubnetRtName"
az network route-table create `
  --name $gatewaySubnetRtName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Associating $gatewaySubnetRtName to $gatewaySubnetName"
az network vnet subnet update `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name $gatewaySubnetName `
  --route-table $gatewaySubnetRtName `
  --only-show-errors `
  --output None

Write-Host "Creating spoke virtual network variables"
$spokeVirtualNetworks = @(
  "1",
  "2",
  "3"
)

foreach ($spokeVirtualNetwork in $spokeVirtualNetworks) {

  $resourceGroupName = "rg-learn-0$($spokeVirtualNetwork)"
  $virtualNetworkName = "vnet-learn-0$($spokeVirtualNetwork)"
  $virtualNetworkAddress = "10.$($spokeVirtualNetwork).0.0/16"
  $subnetName = "snet-learn-0$($spokeVirtualNetwork)"
  $subnetRtName = "rt-$subnetName"
  
  Write-Host "Retrieving peerings: $VirtualNetworkName"
  $spokePeerings = az network vnet peering list `
    --vnet-name $virtualNetworkName `
    --resource-group $resourceGroupName `
    --only-show-errors `
    --output json | ConvertFrom-Json
    
  foreach ($spokePeering in $spokePeerings) {

    $spokePeeringName = $spokePeering.name
    $spokePeeringId = $spokePeering.id
    
    Write-Host "Deleting use remote gateway: $spokePeeringName"
    az network vnet peering update `
      --ids $spokePeeringId `
      --remove use_remote_gateways `
      --only-show-errors `
      --output None
  }

  Write-Host "Retrieving spoke routes: $subnetRtName"
  $spokeRoutes = az network route-table route list `
    --route-table-name $subnetRtName `
    --resource-group $resourceGroupName `
    --only-show-errors `
    --output json | ConvertFrom-Json
  
  foreach ($spokeRoute in $spokeRoutes) {

    $spokeRouteName = $spokeRoute.name
    $spokeRouteId = $spokeRoute.id

    Write-Host "Deleting spoke route: $spokeRouteName"
    az network route-table route delete `
      --ids $spokeRouteId `
      --only-show-errors `
      --output None
  }

  Write-Host "Creating gateway route: $virtualNetworkName"
  az network route-table route create `
    --route-table-name $gatewaySubnetRtName `
    --resource-group $resourceGroupHubName `
    --name $virtualNetworkName `
    --address-prefix $virtualNetworkAddress `
    --next-hop-type VirtualAppliance `
    --next-hop-ip-address $firewallPrivateIp `
    --only-show-errors `
    --output None
    
  Write-Host "Creating default route via firewall"
  az network route-table route create `
    --route-table-name $subnetRtName `
    --resource-group $resourceGroupName `
    --name default `
    --address-prefix 0.0.0.0/0 `
    --next-hop-type VirtualAppliance `
    --next-hop-ip-address $firewallPrivateIp `
    --only-show-errors `
    --output None
}
 
Write-Host "Deployment complete"