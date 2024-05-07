Write-Host "Creating variables"
$resourceGroup01Name = "rg-learn-01"
$resourceGroupLocation = "uksouth"
$virtualNetwork01Name = "vnet-learn-01"
$subnet01Name = "snet-learn-01"
$subnet01NsgName = "nsg-$subnet01Name"
$virtualMachine01Name = "vm-learn-01"
$virtualMachine01NicName = "$virtualMachine01Name-nic"
$resourceGroup02Name = "rg-learn-02"
$virtualNetwork02Name = "vnet-learn-02"
$virtualNetwork02Address = "10.2.0.0/16"
$subnet02Name = "snet-learn-02"
$subnet02NsgName = "nsg-$subnet02Name"
$subnet02Address = "10.2.1.0/24"
$virtualMachine02Name = "vm-learn-02"
$virtualMachine02NicName = "$virtualMachine02Name-nic"
$virtualMachine02DiskName = "$virtualMachine02Name-disk-os"
$virtualMachineSize = "Standard_B1ls"
$virtualMachineImage = "Ubuntu2204"
$virtualMachineUsername = "learnadmin"
$virtualMachinePassword = "ReplaceMe24!"

Write-Host "Retrieving security rules from $subnet01NsgName"
$subnet01NsgRules = az network nsg rule list `
  --nsg-name $subnet01NsgName `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output json | ConvertFrom-Json

foreach ($subnet01NsgRule in $subnet01NsgRules) {

  $nsgRuleName = $subnet01NsgRule.name

  Write-Host "Deleting $nsgRuleName from $subnet01NsgName"
  az network nsg rule delete `
    --nsg-name $subnet01NsgName `
    --resource-group $resourceGroup01Name `
    --name $nsgRuleName `
    --only-show-errors `
    --output None
}

Write-Host "Disassociating application security groups: $virtualMachine01NicName"
az network nic ip-config update `
  --nic-name $virtualMachine01NicName `
  --resource-group $resourceGroup01Name `
  --name ipconfig1 `
  --remove application_security_groups `
  --only-show-errors `
  --output None

Write-Host "Retrieving virtual machines from $resourceGroup01Name"
$virtualMachines = az vm list `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output json | ConvertFrom-Json

foreach ($virtualMachine in $virtualMachines) {

  $virtualMachineName = $virtualMachine.name
  $virtualMachineNicId = $virtualMachine.networkProfile.networkInterfaces.id
  $virtualMachineNicName = $virtualMachineNicId.split("/")[-1]
  $virtualMachineDiskName = $virtualMachine.storageProfile.osDisk.name

  if ($virtualMachineName -eq $virtualMachine01Name) {

    Write-Host "Preserving $virtualMachineName"
  }
  else {

    Write-Host "Deleting virtual machine: $virtualMachineName"
    az vm delete `
      --name $virtualMachineName `
      --resource-group $resourceGroup01Name `
      --yes `
      --only-show-errors `
      --output None

    Write-Host "Deleting network interface: $virtualMachineNicName"
    az network nic delete `
      --name $virtualMachineNicName `
      --resource-group $resourceGroup01Name `
      --only-show-errors `
      --output None

    Write-Host "Deleting disk: $virtualMachineDiskName"
    az disk delete `
      --disk-name $virtualMachineDiskName `
      --resource-group $resourceGroup01Name `
      --yes `
      --no-wait `
      --only-show-errors `
      --output None
  }
}

Write-Host "Deleting subnet: $subnet02Name"
az network vnet subnet delete `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name $subnet02Name `
  --only-show-errors `
  --output None

Write-Host "Deleting network security group: $subnet02NsgName"
az network nsg delete `
  --name $subnet02NsgName `
  --resource-group $resourceGroup01Name `
  --no-wait `
  --only-show-errors `
  --output None

Write-Host "Retrieving application security groups from $resourceGroup01Name"
$applicationSecurityGroups = az network asg list `
  --resource-group $resourceGroup01Name `
  --only-show-errors `
  --output json | ConvertFrom-Json

foreach ($applicationSecurityGroup in $applicationSecurityGroups) {

  $applicationSecurityGroupName = $applicationSecurityGroup.name

  Write-Host "Deleting application security group: $applicationSecurityGroupName"  
  az network asg delete `
    --name $applicationSecurityGroupName `
    --resource-group $resourceGroup01Name `
    --no-wait `
    --only-show-errors `
    --output None
}

Write-Host "Creating resource group: $resourceGroup02Name"
az group create `
  --name $resourceGroup02Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating virtual network: $virtualNetwork02Name"
$virtualNetwork02Id = az network vnet create `
  --name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --address-prefixes $virtualNetwork02Address `
  --query newVNet.id `
  --only-show-errors `
  --output tsv

Write-Host "Creating network security group: $subnet02NsgName"
az network nsg create `
  --name $subnet02NsgName `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --only-show-errors `
  --output None

Write-Host "Creating subnet: $subnet02Name"
az network vnet subnet create `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name $subnet02Name `
  --address-prefixes $subnet02Address `
  --network-security-group $subnet02NsgName `
  --only-show-errors `
  --output None

Write-Host "Create network interface: $virtualMachine02NicName"
az network nic create `
  --name $virtualMachine02NicName `
  --resource-group $resourceGroup02Name `
  --location $resourceGroupLocation `
  --vnet-name $virtualNetwork02Name `
  --subnet $subnet02Name `
  --only-show-errors `
  --output None

Write-Host "Creating virtual machine: $virtualMachine02Name"
az vm create `
  --name $virtualMachine02Name `
  --resource-group $resourceGroup02Name `
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

Write-Host "Retrieving virtual network: $virtualNetwork01Name"
$virtualNetwork01Id = az network vnet show `
  --name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --query id `
  --only-show-errors `
  --output tsv

Write-Host "Peering $virtualNetwork01Name to $virtualNetwork02Name"
az network vnet peering create `
  --vnet-name $virtualNetwork01Name `
  --resource-group $resourceGroup01Name `
  --name peer-$virtualNetwork01Name-to-$virtualNetwork02Name `
  --remote-vnet $virtualNetwork02Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Peering $virtualNetwork02Name to $virtualNetwork01Name"
az network vnet peering create `
  --vnet-name $virtualNetwork02Name `
  --resource-group $resourceGroup02Name `
  --name peer-$virtualNetwork02Name-to-$virtualNetwork01Name `
  --remote-vnet $virtualNetwork01Id `
  --allow-vnet-access `
  --only-show-errors `
  --output None

Write-Host "Deployment complete"
