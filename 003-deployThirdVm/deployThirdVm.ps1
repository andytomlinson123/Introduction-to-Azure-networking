Write-Host "Creating variables"
$resourceGroupName = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$logAnalyticsName = "laws-learn-01"
$storageAccountName = "stlearn01flowlogs" # must be globally unique
$virtualNetworkName = "vnet-learn-01"
$subnetName = "snet-learn-02"
$subnetNsgName = "nsg-$subnetName"
$subnetAddress = "10.1.2.0/24"
$nsgFlowLogsName = "$subnetNsgName-flow-logs"
$nsgFlowLogsVersion = "2"
$nsgFlowLogsInterval = "10"
$nsgFlowLogsRetention = "30"
$asgRestrictSubnetName = "asg-restrict-snet-learn-02"
$asgAllowSubnetName = "asg-allow-snet-learn-02"
$asgRestrictInternetName = "asg-restrict-internet"
$asgAllowInternetName = "asg-allow-internet"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
$virtualMachine02Name = "vm-learn-02"
$virtualMachine02NicName = "$virtualMachine02Name-nic"
$virtualMachine03Name = "vm-learn-03"
$virtualMachine03NicName = "$virtualMachine03Name-nic"
$virtualMachine03DiskName = "$virtualMachine03Name-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

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

Write-Host "Creating application security group: $asgRestrictSubnetName"
az network asg create `
  --name $asgRestrictSubnetName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating application security group: $asgAllowSubnetName"
az network asg create `
  --name $asgAllowSubnetName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating security rule: restrict-subnet-inbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --direction Inbound `
  --name restrict-subnet-inbound `
  --priority 100 `
  --access Allow `
  --source-asgs $asgRestrictSubnetName `
  --destination-address-prefixes $subnetAddress `
  --protocol Tcp `
  --destination-port-ranges 22 `
  --only-show-errors `
  --output None
      
Write-Host "Creating security rule: allow-subnet-inbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --direction Inbound `
  --name allow-subnet-inbound `
  --priority 200 `
  --access Allow `
  --source-asgs $asgAllowSubnetName `
  --destination-address-prefixes $subnetAddress `
  --protocol "*" `
  --destination-port-ranges "*" `
  --only-show-errors `
  --output None
      
Write-Host "Creating security rule: deny-subnet-inbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --direction Inbound `
  --name deny-subnet-inbound `
  --priority 300 `
  --access Deny `
  --source-address-prefixes VirtualNetwork `
  --destination-address-prefixes $subnetAddress `
  --protocol "*" `
  --destination-port-ranges "*" `
  --only-show-errors `
  --output None
      
Write-Host "Creating security rule: allow-internet-outbound"
az network nsg rule create `
  --nsg-name $subnetNsgName `
  --resource-group $resourceGroupName `
  --direction Outbound `
  --name allow-internet-outbound `
  --priority 100 `
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
  --direction Outbound `
  --name deny-internet-outbound `
  --priority 200 `
  --access Deny `
  --source-address-prefixes "*" `
  --destination-address-prefixes Internet `
  --protocol "*" `
  --destination-port-ranges "*" `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnetName"
az network vnet subnet create `
  --name $subnetName `
  --resource-group $resourceGroupName `
  --vnet-name $virtualNetworkName `
  --address-prefixes $subnetAddress `
  --network-security-group $subnetNsgName `
  --only-show-errors `
  --output None

Write-Host "Creating network interface: $virtualMachine03NicName"
az network nic create `
  --name $virtualMachine03NicName `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetworkName `
  --subnet $subnetName `
  --application-security-groups $asgAllowInternetName `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachine03Name"
az vm create `
  --name $virtualMachine03Name `
  --resource-group $resourceGroupName `
  --location $resourceGroupLocation `
  --size $virtualMachineSize `
  --admin-username $virtualMachineUsername `
  --admin-password $virtualMachinePassword `
  --image $virtualMachineImage `
  --os-disk-name $virtualMachine03DiskName `
  --storage-sku StandardSSD_LRS `
  --nics $virtualMachine03NicName `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Updating $virtualMachine01NicName to apply application security groups"
az network nic ip-config update `
  --name ipconfig1 `
  --nic-name $virtualMachine01NicName `
  --resource-group $resourceGroupName `
  --application-security-groups $asgRestrictInternetName $asgRestrictSubnetName `
  --only-show-errors `
  --output None
  
Write-Host "Updating $virtualMachine02NicName to apply application security groups"
az network nic ip-config update `
  --name ipconfig1 `
  --nic-name $virtualMachine02NicName `
  --resource-group $resourceGroupName `
  --application-security-groups $asgAllowInternetName $asgAllowSubnetName `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"