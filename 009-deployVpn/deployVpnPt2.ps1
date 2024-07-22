Write-Host "Creating variables"
$resourceGroupHubName = "rg-learn-hub"
$resourceGroupLocation = "uksouth"
$virtualNetworkGatewayHubName = "gw-learn-hub"
$virtualNetworkGatewayHubIpName = "$virtualNetworkGatewayHubName-ip"
$localNetworkGatewayHubName = "lng-learn-hub"
$virtualNetworkHubAddress = "10.0.0.0/16"
$virtualNetwork01Address = "10.1.0.0/16"
$virtualNetwork02Address = "10.2.0.0/16"
$virtualNetwork03Address = "10.3.0.0/16"   
$resourceGroupDcName = "rg-learn-dc"
$virtualNetworkGatewayDcName = "gw-learn-dc"
$virtualNetworkGatewayDcIpName = "$virtualNetworkGatewayDcName-ip"
$localNetworkGatewayDcName = "lng-learn-dc"
$virtualNetworkDcAddress = "10.127.0.0/16"
$connectionNameHub = "con-$virtualNetworkGatewayDcName"
$connectionNameDc = "con-$virtualNetworkGatewayHubName"
$connectionPreSharedKey = "ReplaceMe24!"

Write-Host "Retrieving public IP address: $virtualNetworkGatewayHubIpName"
$virtualNetworkGatewayHubIp = az network public-ip show `
  --name $virtualNetworkGatewayHubIpName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --query ipAddress `
  --output tsv

Write-Host "Retrieving public IP address: $virtualNetworkGatewayDcIpName"
$virtualNetworkGatewayDcIp = az network public-ip show `
  --name $virtualNetworkGatewayDcIpName `
  --resource-group $resourceGroupDcName `
  --only-show-errors `
  --query ipAddress `
  --output tsv

Write-Host "Creating local network gateway: $localNetworkGatewayHubName"
az network local-gateway create `
  --name $localNetworkGatewayHubName `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --gateway-ip-address $virtualNetworkGatewayHubIp `
  --address-prefixes $virtualNetworkHubAddress $virtualNetwork01Address $virtualNetwork02Address $virtualNetwork03Address `
  --only-show-errors `
  --output None

Write-Host "Creating local network gateway: $localNetworkGatewayDcName"
az network local-gateway create `
  --name $localNetworkGatewayDcName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --gateway-ip-address $virtualNetworkGatewayDcIp `
  --address-prefixes $virtualNetworkDcAddress `
  --only-show-errors `
  --output None

Write-Host "Creating site to site connection: $connectionNameHub"
az network vpn-connection create `
  --name $connectionNameHub `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --vnet-gateway1 $virtualNetworkGatewayHubName `
  --local-gateway2 $localNetworkGatewayDcName `
  --shared-key $connectionPreSharedKey `
  --only-show-errors `
  --output None

Write-Host "Creating site to site connection: $connectionNameDc"
az network vpn-connection create `
  --name $connectionNameDc `
  --resource-group $resourceGroupDcName `
  --location $resourceGroupLocation `
  --vnet-gateway1 $virtualNetworkGatewayDcName `
  --local-gateway2 $localNetworkGatewayHubName `
  --shared-key $connectionPreSharedKey `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"