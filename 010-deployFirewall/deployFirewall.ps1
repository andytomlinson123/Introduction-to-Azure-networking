Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$logAnalyticsName = "laws-learn-hub"
$virtualNetwork01Name = "vnet-learn-01"
$virtualNetwork01Address = "10.1.0.0/16"
$subnet01Name = "snet-learn-01"
$subnet01RtName = "rt-$subnet01Name"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
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
$gatewaySubnetName = "GatewaySubnet"
$gatewaySubnetRtName = "rt-$gatewaySubnetName"
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
  --name rcg-dnat `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --priority 1000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-dnat"
az network firewall policy rule-collection-group collection add-nat-collection `
  --name rc-dnat `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --rcg-name rcg-dnat `
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
  --name rcg-network `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --priority 2000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-network"
az network firewall policy rule-collection-group collection add-filter-collection `
  --name rc-network `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --rcg-name rcg-network `
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
  --collection-name rc-network `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --rcg-name rcg-network `
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
  --name rcg-application `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --priority 3000 `
  --only-show-errors `
  --output None

Write-Host "Creating rule collection: rc-application"
az network firewall policy rule-collection-group collection add-filter-collection `
  --name rc-application `
  --resource-group $resourceGroupHubName `
  --policy-name $firewallPolicyName `
  --rcg-name rcg-application `
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
  --query id `
  --only-show-errors `
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

Write-Host "Retrieving private IP address: $firewallName"
$firewallPrivateIp = az network firewall show `
  --name $firewallName `
  --resource-group $resourceGroupHubName `
  --only-show-errors `
  --query ipConfigurations[0].privateIPAddress `
  --output tsv
  
Write-Host "Creating route table: $gatewaySubnetRtName"
az network route-table create `
  --name $gatewaySubnetRtName `
  --resource-group $resourceGroupHubName `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork01Name"
az network route-table route create `
  --route-table-name $gatewaySubnetRtName `
  --resource-group $resourceGroupHubName `
  --name $virtualNetwork01Name `
  --address-prefix $virtualNetwork01Address `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork02Name"
az network route-table route create `
  --route-table-name $gatewaySubnetRtName `
  --resource-group $resourceGroupHubName `
  --name $virtualNetwork02Name `
  --address-prefix $virtualNetwork02Address `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: $virtualNetwork03Name"
az network route-table route create `
  --route-table-name $gatewaySubnetRtName `
  --resource-group $resourceGroupHubName `
  --name $virtualNetwork03Name `
  --address-prefix $virtualNetwork03Address `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Associating $gatewaySubnetRtName to $gatewaySubnetName"
az network vnet subnet update `
  --vnet-name $virtualNetworkHubName `
  --name $gatewaySubnetName `
  --resource-group $resourceGroupHubName `
  --route-table $gatewaySubnetRtName `
  --only-show-errors `
  --output None
  
Write-Host "Disabling gateway route propagation: $subnet01RtName"
az network route-table update `
  --name $subnet01RtName `
  --resource-group $resourceGroup01Name `
  --disable-bgp-route-propagation `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork02Name"
az network route-table route delete `
  --route-table-name $subnet01RtName `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork03Name"
az network route-table route delete `
  --route-table-name $subnet01RtName `
  --name $virtualNetwork03Name `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output None
  
Write-Host "Creating route: default"
az network route-table route create `
  --route-table-name $subnet01RtName `
  --resource-group $resourceGroup01Name `
  --name default `
  --address-prefix 0.0.0.0/0 `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Disabling gateway route propagation: $subnet02RtName"
az network route-table update `
  --name $subnet02RtName `
  --resource-group $resourceGroup02Name `
  --disable-bgp-route-propagation `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork01Name"
az network route-table route delete `
  --route-table-name $subnet02RtName `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup02Name `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork03Name"
az network route-table route delete `
  --route-table-name $subnet02RtName `
  --name $virtualNetwork03Name `
  --resource-group $resourceGroup02Name `
  --only-show-errors `
  --output None
    
Write-Host "Creating route: default"
az network route-table route create `
  --route-table-name $subnet02RtName `
  --resource-group $resourceGroup02Name `
  --name default `
  --address-prefix 0.0.0.0/0 `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Disabling gateway route propagation: $subnet03RtName"
az network route-table update `
  --name $subnet03RtName `
  --resource-group $resourceGroup03Name `
  --disable-bgp-route-propagation `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork01Name"
az network route-table route delete `
  --route-table-name $subnet03RtName `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup03Name `
  --only-show-errors `
  --output None
  
Write-Host "Deleting route: $virtualNetwork02Name"
az network route-table route delete `
  --route-table-name $subnet03RtName `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup03Name `
  --only-show-errors `
  --output None
    
Write-Host "Creating route: default"
az network route-table route create `
  --route-table-name $subnet03RtName `
  --resource-group $resourceGroup03Name `
  --name default `
  --address-prefix 0.0.0.0/0 `
  --next-hop-type VirtualAppliance `
  --next-hop-ip-address $firewallPrivateIp `
  --only-show-errors `
  --output None
  
Write-Host "Deployment complete"