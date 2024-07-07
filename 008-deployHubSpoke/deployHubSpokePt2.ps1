Write-Host "Creating variables"
$resourceGroupLocation = "uksouth"
$resourceGroupHubName = "rg-learn-hub"
$virtualNetworkHubName = "vnet-learn-hub"

Write-Host "Retrieving virtual network: $virtualNetworkHubName"
$virtualNetworkHubId = az network vnet show `
  --name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Creating spoke virtual network variables"
$spokeVirtualNetworks = @(
  "01",
  "02",
  "03"
)

foreach ($spokeVirtualNetwork in $spokeVirtualNetworks) {

  $resourceGroupName = "rg-learn-$($spokeVirtualNetwork)"
  $virtualNetworkName = "vnet-learn-$($spokeVirtualNetwork)"
  $subnetName = "snet-learn-$($spokeVirtualNetwork)"
  $subnetRtName = "rt-$subnetName"

  Write-Host "Retrieving virtual network: $virtualNetworkName"
  $virtualNetworkId = az network vnet show `
    --name $virtualNetworkName `
    --resource-group $resourceGroupName `
    --only-show-errors `
    --query id `
    --output tsv

  Write-Host "Peering $virtualNetworkHubName to $virtualNetworkName"
  az network vnet peering create `
    --vnet-name $virtualNetworkHubName `
    --resource-group $resourceGroupHubName `
    --name peer-$virtualNetworkHubName-to-$virtualNetworkName `
    --remote-vnet $virtualNetworkId `
    --allow-vnet-access `
    --allow-gateway-transit `
    --only-show-errors `
    --output None

  Write-Host "Peering $virtualNetworkName to $virtualNetworkHubName"
  az network vnet peering create `
    --vnet-name $virtualNetworkName `
    --resource-group $resourceGroupName `
    --name peer-$virtualNetworkName-to-$virtualNetworkHubName `
    --remote-vnet $virtualNetworkHubId `
    --allow-vnet-access `
    --allow-forwarded-traffic `
    --use-remote-gateways `
    --only-show-errors `
    --output None

  Write-Host "Creating route table: $subnetRtName"
  az network route-table create `
    --name $subnetRtName `
    --resource-group $resourceGroupName `
    --location $resourceGroupLocation `
    --only-show-errors `
    --output None

  Write-Host "Associating $subnetRtName to $subnetName"
  az network vnet subnet update `
    --vnet-name $virtualNetworkName `
    --resource-group $resourceGroupName `
    --name $subnetName `
    --route-table $subnetRtName `
    --only-show-errors `
    --output None

  Write-Host "Creating spoke virtual network route variables"
  switch ($spokeVirtualNetwork) {
    "01" { $virtualNetworkRoutes = @("2", "3") }
    "02" { $virtualNetworkRoutes = @("1", "3") }
    "03" { $virtualNetworkRoutes = @("1", "2") }
  }

  foreach ($virtualNetworkRoute in $virtualNetworkRoutes) {

    $virtualNetworkName = "vnet-learn-0$($virtualNetworkRoute)"
    $virtualNetworkAddress = "10.$($virtualNetworkRoute).0.0/16"

    Write-Host "Creating route: $virtualNetworkName"
    az network route-table route create `
      --route-table-name $subnetRtName `
      --resource-group $resourceGroupName `
      --name $virtualNetworkName `
      --address-prefix $virtualNetworkAddress `
      --next-hop-type VirtualNetworkGateway `
      --only-show-errors `
      --output None
  }
}

Write-Host "Deployment complete"