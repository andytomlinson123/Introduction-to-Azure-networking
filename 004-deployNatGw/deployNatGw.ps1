Write-Host "Creating variables"
$resourceGroupName = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetworkName = "vnet-learn-01"
$subnet01Name = "snet-learn-01"
$subnet01NsgName = "nsg-$subnet01Name"
$subnet01NsgFlowLogsName = "$subnet01NsgName-flow-logs"
$subnet02Name = "snet-learn-02"
$subnet02NsgName = "nsg-$subnet02Name"
$subnet02NsgFlowLogsName = "$subnet02NsgName-flow-logs"
$logAnalyticsName = "laws-learn-01"
$storageAccountName = "stlearn01flowlogs" # must be globally unique
$natGwName = "natgw-learn-01"
$natGwIpName = "$natGwName-ip"

Write-Host "Deleting flow logs: $subnet01NsgFlowLogsName"
az network watcher flow-log delete `
  --name $subnet01NsgFlowLogsName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Deleting flow logs: $subnet02NsgFlowLogsName"
az network watcher flow-log delete `
  --name $subnet02NsgFlowLogsName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Deleting log analytics workspace: $logAnalyticsName"
az monitor log-analytics workspace delete `
  --name $logAnalyticsName `
  --resource-group $resourceGroupName `
  --force `
  --yes `
  --only-show-errors `
  --output None

Write-Host "Deleting storage account: $storageAccountName"
az storage account delete `
  --name $storageAccountName `
  --resource-group $resourceGroupName `
  --yes `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $natGwIpName"
az network public-ip create `
  --name $natGwIpName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating NAT gateway: $natGwName"
az network nat gateway create `
  --name $natGwName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --public-ip-address $natGwIpName `
  --only-show-errors `
  --output None

Write-Host "Associating $natGwName to $subnet01Name"
az network vnet subnet update `
  --vnet-name $virtualNetworkName `
  --resource-group $resourceGroupName `
  --name $subnet01Name `
  --nat-gateway $natGwName `
  --only-show-errors `
  --output None

Write-Host "Associating $natGwName to $subnet02Name"
az network vnet subnet update `
  --vnet-name $virtualNetworkName `
  --resource-group $resourceGroupName `
  --name $subnet02Name `
  --nat-gateway $natGwName `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"