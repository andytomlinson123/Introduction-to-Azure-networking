Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$virtualNetwork01Name = "vnet-learn-01"
$resourceGroup03Name = "rg-learn-03"
$virtualNetwork03Name = "vnet-learn-03"

Write-Host "Retrieving virtual network: $virtualNetwork01Name"
$virtualNetwork01Id = az network vnet show `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
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

Write-Host "Peering $virtualNetwork01Name to $virtualNetwork03Name"
az network vnet peering create `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetwork03Name `
  --remote-vnet $virtualNetwork03Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetwork03Name to $virtualNetwork01Name"
az network vnet peering create `
  --vnet-name $virtualNetwork03Name `
  --resource-group $resourceGroup03Name `
  --name peer-$virtualNetwork03Name-to-$virtualNetwork01Name `
  --remote-vnet $virtualNetwork01Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"