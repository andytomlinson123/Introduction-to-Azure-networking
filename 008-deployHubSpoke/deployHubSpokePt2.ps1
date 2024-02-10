Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetwork01Name = "vnet-learn-01"
$virtualNetwork01Address = "10.1.0.0/16"
$subnet01Name = "snet-learn-01"
$subnet01RtName = "rt-$subnet01Name"
$resourceGroup02Name = "rg-learn-02"
$virtualNetwork02Name = "vnet-learn-02"
$virtualNetwork02Address = "10.2.0.0/16"
$subnet02Name = "snet-learn-02"
$subnet02RtName = "rt-$subnet02Name"
$resourceGroup03Name = "rg-learn-03"
$virtualNetwork03Name = "vnet-learn-03"
$virtualNetwork03Address = "10.3.0.0/16"
$subnet03Name = "snet-learn-03"
$subnet03RtName = "rt-$subnet03Name"
$resourceGroupHubName = "rg-learn-hub"
$virtualNetworkHubName = "vnet-learn-hub"

Write-Host "Retrieving virtual network: $virtualNetwork01Name"
$virtualNetwork01Id = az network vnet show `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Retrieving virtual network: $virtualNetwork02Name"
$virtualNetwork02Id = az network vnet show `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Retrieving virtual network: $virtualNetwork03Name"
$virtualNetwork03Id = az network vnet show `
  --name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Retrieving virtual network: $virtualNetworkHubName"
$virtualNetworkHubId = az network vnet show `
  --name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Peering $virtualNetworkHubName to $virtualNetwork01Name"
az network vnet peering create `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name peer-$virtualNetworkHubName-to-$virtualNetwork01Name `
  --remote-vnet $virtualNetwork01Id `
  --allow-vnet-access `
  --allow-gateway-transit `
  --only-show-errors `
  --output None
  
Write-Host "Peering $virtualNetwork01Name to $virtualNetworkHubName"
az network vnet peering create `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetworkHubName `
  --remote-vnet $virtualNetworkHubId `
  --allow-vnet-access `
  --allow-forwarded-traffic `
  --use-remote-gateways `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetworkHubName to $virtualNetwork02Name"
az network vnet peering create `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name peer-$virtualNetworkHubName-to-$virtualNetwork02Name `
  --remote-vnet $virtualNetwork02Id `
  --allow-vnet-access `
  --allow-gateway-transit `
  --only-show-errors `
  --output None
  
Write-Host "Peering $virtualNetwork02Name to $virtualNetworkHubName"
az network vnet peering create `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetworkHubName `
  --remote-vnet $virtualNetworkHubId `
  --allow-vnet-access `
  --allow-forwarded-traffic `
  --use-remote-gateways `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetworkHubName to $virtualNetwork03Name"
az network vnet peering create `
  --vnet-name $virtualNetworkHubName `
  --resource-group $resourceGroupHubName `
  --name peer-$virtualNetworkHubName-to-$virtualNetwork03Name `
  --remote-vnet $virtualNetwork03Id `
  --allow-vnet-access `
  --allow-gateway-transit `
  --only-show-errors `
  --output None
  
Write-Host "Peering $virtualNetwork03Name to $virtualNetworkHubName"
az network vnet peering create `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name peer-$virtualNetwork03Name-to-$virtualNetworkHubName `
  --remote-vnet $virtualNetworkHubId `
  --allow-vnet-access `
  --allow-forwarded-traffic `
  --use-remote-gateways `
  --only-show-errors `
  --output None

Write-Host "Creating route table: $subnet01RtName"
az network route-table create `
  --name $subnet01RtName `
  --resource-group $resourceGroup01Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork02Name"
az network route-table route create `
  --route-table-name $subnet01RtName `
  --resource-group $resourceGroup01Name `
  --name $virtualNetwork02Name `
  --address-prefix $virtualNetwork02Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Creating route: $virtualNetwork03Name"
az network route-table route create `
  --route-table-name $subnet01RtName `
  --resource-group $resourceGroup01Name `
  --name $virtualNetwork03Name `
  --address-prefix $virtualNetwork03Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Associating $subnet01RtName to $subnet01Name"
az network vnet subnet update `
  --vnet-name $virtualNetwork01Name `
  --name $subnet01Name `
  --resource-group $resourceGroup01Name `
  --route-table $subnet01RtName `
  --only-show-errors `
  --output None

Write-Host "Creating route table: $subnet02RtName"
az network route-table create `
  --name $subnet02RtName `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork01Name"
az network route-table route create `
  --route-table-name $subnet02RtName `
  --resource-group $resourceGroup02Name `
  --name $virtualNetwork01Name `
  --address-prefix $virtualNetwork01Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Creating route: $virtualNetwork03Name"
az network route-table route create `
  --route-table-name $subnet02RtName `
  --resource-group $resourceGroup02Name `
  --name $virtualNetwork03Name `
  --address-prefix $virtualNetwork03Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Associating $subnet02RtName to $subnet02Name"
az network vnet subnet update `
  --vnet-name $virtualNetwork02Name `
  --name $subnet02Name `
  --resource-group $resourceGroup02Name `
  --route-table $subnet02RtName `
  --only-show-errors `
  --output None

Write-Host "Creating route table: $subnet03RtName"
az network route-table create `
  --name $subnet03RtName `
  --resource-group $resourceGroup03Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork01Name"
az network route-table route create `
  --route-table-name $subnet03RtName `
  --resource-group $resourceGroup03Name `
  --name $virtualNetwork01Name `
  --address-prefix $virtualNetwork01Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Creating route: $virtualNetwork02Name"
az network route-table route create `
  --route-table-name $subnet03RtName `
  --resource-group $resourceGroup03Name `
  --name $virtualNetwork02Name `
  --address-prefix $virtualNetwork02Address `
  --next-hop-type VirtualNetworkGateway `
  --only-show-errors `
  --output None

Write-Host "Associating $subnet03RtName to $subnet03Name"
az network vnet subnet update `
  --vnet-name $virtualNetwork03Name `
  --name $subnet03Name `
  --resource-group $resourceGroup03Name `
  --route-table $subnet03RtName `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"