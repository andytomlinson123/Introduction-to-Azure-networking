Write-Host "Creating variables"
$resourceGroupName = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$logAnalyticsName = "laws-learn-01"
$logAnalyticsSku = "PerGB2018"
$logAnalyticsQuota = "0.1"
$logAnalyticsRetention = "30"
$storageAccountName = "stlearn01flowlogs" # must be globally unique
$storageAccountKind = "StorageV2"
$storageAccountSku = "Standard_LRS"
$virtualNetworkName = "vnet-learn-01"
$subnetName = "snet-learn-01"
$subnetNsgName = "nsg-$subnetName"
$nsgFlowLogsName = "$subnetNsgName-flow-logs"
$nsgFlowLogsVersion = "2"
$nsgFlowLogsInterval = "10"
$nsgFlowLogsRetention = "30"
$asgRestrictInternetName = "asg-restrict-internet"
$asgAllowInternetName = "asg-allow-internet"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
$virtualMachine01NsgName = "$virtualMachine01Name-nsg"
$virtualMachine02Name = "vm-learn-02"
$virtualMachine02NicName = "$virtualMachine02Name-nic"
$virtualMachine02DiskName = "$virtualMachine02Name-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Creating log analytics workspace: $logAnalyticsName"
az monitor log-analytics workspace create `
  --name $logAnalyticsName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --sku $logAnalyticsSku `
  --quota $logAnalyticsQuota `
  --retention-time $logAnalyticsRetention `
  --only-show-errors `
  --output None

Write-Host "Creating storage account: $storageAccountName"
az storage account create `
  --name $storageAccountName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --kind $storageAccountKind `
  --sku $storageAccountSku `
  --min-tls-version TLS1_2 `
  --only-show-errors `
  --output None

Write-Host "Creating network security group: $subnetNsgName"
az network nsg create `
  --name $subnetNsgName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating flow logs: $nsgFlowLogsName"
az network watcher flow-log create `
  --name $nsgFlowLogsName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --nsg $subnetNsgName `
  --workspace $logAnalyticsName `
  --storage-account $storageAccountName `
  --log-version $nsgFlowLogsVersion `
  --interval $nsgFlowLogsInterval `
  --retention $nsgFlowLogsRetention `
  --traffic-analytics `
  --only-show-errors `
  --output None

Write-Host "Creating application security group: $asgRestrictInternetName"
az network asg create `
  --name $asgRestrictInternetName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating application security group: $asgAllowInternetName"
az network asg create `
  --name $asgAllowInternetName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Retrieving your public IP address"
$yourPublicIp = Invoke-WebRequest -Uri https://ipinfo.io | ConvertFrom-Json
  
Write-Host "Retrieving private IP address: $virtualMachine01Name"
$virtualMachine01PrivateIp = az network nic show `
  --name $virtualMachine01NicName `
  --resource-group $resourceGroupName `
  --query ipConfigurations[0].privateIPAddress `
  --only-show-errors `
  --output tsv
  
Write-Host "Creating security rule: allow-ssh-inbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --name allow-ssh-inbound `
  --direction Inbound `
  --priority 100 `
  --access Allow `
  --source-address-prefixes $yourPublicIp.ip `
  --destination-address-prefixes $virtualMachine01PrivateIp `
  --protocol Tcp `
  --destination-port-ranges 22 `
  --only-show-errors `
  --output None
  
Write-Host "Creating security rule: restrict-internet-outbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --name restrict-internet-outbound `
  --direction Outbound `
  --priority 100 `
  --access Allow `
  --source-asgs $asgRestrictInternetName `
  --destination-address-prefixes 34.117.186.192  `
  --protocol Tcp `
  --destination-port-ranges 443 `
  --only-show-errors `
  --output None
  
Write-Host "Creating security rule: allow-internet-outbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --name allow-internet-outbound `
  --direction Outbound `
  --priority 200 `
  --access Allow `
  --source-asgs $asgAllowInternetName `
  --destination-address-prefixes Internet `
  --protocol "*" `
  --destination-port-ranges "*" `
  --only-show-errors `
  --output None
  
Write-Host "Creating security rule: deny-internet-outbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --name deny-internet-outbound `
  --direction Outbound `
  --priority 300 `
  --access Deny `
  --source-address-prefixes "*" `
  --destination-address-prefixes Internet `
  --protocol "*" `
  --destination-port-ranges "*" `
  --only-show-errors `
  --output None

Write-Host "Associating $subnetNsgName to $subnetName"
az network vnet subnet update `
  --vnet-name $virtualNetworkName `
  --resource-group $resourceGroupName `
  --name $subnetName `
  --network-security-group $subnetNsgName `
  --only-show-errors `
  --output None

Write-Host "Creating network interface: $virtualMachine02NicName"
az network nic create `
  --name $virtualMachine02NicName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetworkName `
  --subnet $subnetName `
  --application-security-groups $asgAllowInternetName `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachine02Name"
az vm create `
  --name $virtualMachine02Name `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachine02DiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachine02NicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Updating $virtualMachine01NicName to apply $asgRestrictInternetName"
az network nic ip-config update `
  --nic-name $virtualMachine01NicName `
  --resource-group $resourceGroupName `
  --name ipconfig1 `
  --application-security-groups $asgRestrictInternetName `
  --only-show-errors `
  --output None
  
Write-Host "Disassociating $virtualMachine01NsgName from $virtualMachine01NicName"
az network nic update `
  --name $virtualMachine01NicName `
  --resource-group $resourceGroupName `
  --remove network_security_group `
  --only-show-errors `
  --output None

Write-host "Deleting $virtualMachine01NsgName"
az network nsg delete `
  --name $virtualMachine01NsgName `
  --resource-group $resourceGroupName `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"