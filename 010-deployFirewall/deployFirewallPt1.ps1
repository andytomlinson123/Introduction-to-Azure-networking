Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
$resourceGroupHubName = "rg-learn-hub"
$logAnalyticsName = "laws-learn-hub"
$virtualNetworkHubName = "vnet-learn-hub"
$firewallSubnetName = "AzureFirewallSubnet"
$firewallSubnetAddress = "10.0.2.0/24"
$firewallManagementSubnetName = "AzureFirewallManagementSubnet"
$firewallManagementSubnetAddress = "10.0.3.0/24"
$firewallName = "fw-learn-hub"
$firewallPolicyName = "$firewallName-policy"
$firewallIpName = "$firewallName-ip"
$firewallIpConfigName = "$firewallName-ipconfig"
$firewallManagementIpName = "$firewallName-mgmt-ip"
$firewallManagementIpConfigName = "$firewallName-mgmt-ipconfig"
$firewallDiagnosticsName = "diag-$firewallName"

Write-Host "Creating log analytics workspace: $logAnalyticsName"
az monitor log-analytics workspace create `
  --name $logAnalyticsName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $firewallSubnetName"
az network vnet subnet create `
  --name $firewallSubnetName `
  --resource-group $resourceGroupHubName `
  --vnet-name $virtualNetworkHubName `
  --address-prefixes $firewallSubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $firewallManagementSubnetName"
az network vnet subnet create `
  --name $firewallManagementSubnetName `
  --resource-group $resourceGroupHubName `
  --vnet-name $virtualNetworkHubName `
  --address-prefixes $firewallManagementSubnetAddress `
  --only-show-errors `
  --output None

Write-Host "Creating public IP address: $firewallIpName"
$firewallIp = az network public-ip create `
  --name $firewallIpName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --query publicIp.ipAddress `
  --only-show-errors `
  --output tsv

Write-Host "Creating public IP address: $firewallManagementIpName"
az network public-ip create `
  --name $firewallManagementIpName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Standard `
  --allocation-method Static `
  --only-show-errors `
  --output None

Write-Host "Creating firewall policy: $firewallPolicyName"
az network firewall policy create `
  --name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku Basic `
  --only-show-errors `
  --output None

Write-Host "Retrieving your public IP address"
$yourPublicIp = Invoke-WebRequest -Uri https://ipinfo.io | ConvertFrom-Json

Write-Host "Retrieving private IP address: $virtualMachine01Name"
$virtualMachine01PrivateIp = az network nic show `
  --name $virtualMachine01NicName `
  --resource-group $resourceGroup01Name `
  --query ipConfigurations[0].privateIPAddress `
  --only-show-errors `
  --output tsv

Write-Host "Creating rule collection group: rcg-dnat"
az network firewall policy rule-collection-group create `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --name rcg-dnat `
  --priority 1000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-dnat"
az network firewall policy rule-collection-group collection add-nat-collection `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --rcg-name rcg-dnat `
  --name rc-dnat `
  --collection-priority 1000 `
  --rule-name rule-allow-ssh-inbound `
  --action DNAT `
  --source-addresses $yourPublicIp.ip `
  --destination-address $firewallIp `
  --ip-protocols Tcp `
  --destination-ports 22 `
  --translated-address $virtualMachine01PrivateIp `
  --translated-port 22 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection group: rcg-network"
az network firewall policy rule-collection-group create `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --name rcg-network `
  --priority 2000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-network"
az network firewall policy rule-collection-group collection add-filter-collection `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --rcg-name rcg-network `
  --name rc-network `
  --collection-priority 1000 `
  --rule-name rule-allow-network-outbound `
  --rule-type NetworkRule `
  --action Allow `
  --source-addresses "*" `
  --destination-addresses "*" `
  --ip-protocols Any `
  --destination-ports 1-79 81-442 444-65535 `
  --only-show-errors `
  --output None

Write-Host "Creating rule: rule-allow-network-icmp-outbound"
az network firewall policy rule-collection-group collection rule add `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --rcg-name rcg-network `
  --collection-name rc-network `
  --name rule-allow-network-icmp-outbound `
  --rule-type NetworkRule `
  --source-addresses "*" `
  --destination-addresses "*" `
  --ip-protocols Icmp `
  --destination-ports "*" `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection group: rcg-application"
az network firewall policy rule-collection-group create `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --name rcg-application `
  --priority 3000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-application"
az network firewall policy rule-collection-group collection add-filter-collection `
  --policy-name $firewallPolicyName `
  --resource-group $resourceGroupHubName `
  --rcg-name rcg-application `
  --name rc-application `
  --collection-priority 1000 `
  --rule-name rule-allow-application-outbound `
  --rule-type ApplicationRule `
  --action Allow `
  --source-addresses "*" `
  --target-fqdns "*" `
  --protocols http=80 https=443 `
  --only-show-errors `
  --output None

Write-Host "Creating firewall: $firewallName"
$firewallId = az network firewall create `
  --name $firewallName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --sku AZFW_VNet `
  --tier Basic `
  --conf-name $firewallIpConfigName `
  --public-ip $firewallIpName `
  --m-conf-name $firewallManagementIpConfigName `
  --m-public-ip $firewallManagementIpName `
  --firewall-policy $firewallPolicyName `
  --vnet-name $virtualNetworkHubName `
  --only-show-errors `
  --query id `
  --output tsv

Write-Host "Creating diagnostic setting: $firewallDiagnosticsName"
az monitor diagnostic-settings create `
  --name $firewallDiagnosticsName `
  --resource-group $resourceGroupHubName `
  --resource $firewallId `
  --logs "@firewallLogs.json" `
  --workspace $logAnalyticsName `
  --export-to-resource-specific `
  --only-show-errors `
  --output None
 
Write-Host "Deployment complete"