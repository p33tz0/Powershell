<#
.SYNOPSIS
 This script will assign all the required RBAC permissions to a user or group to be able to access a VM through Azure Bastion.

 This script is provided as is.

.NOTES
  Version:        1.0
  Author:         Petrus Savolainen
  Creation Date:  12-04-2023
#>


# Prompt the user to enter the name of the virtual machine
$vmName = Read-Host "Enter the name of the virtual machine"

# Get the virtual machine by name
$vm = Get-AzVM -Name $vmName

# Get the ID of the virtual machine
$vmId = $vm.Id

# Get the network interface of the virtual machine
$nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].id

# Get the ID of the network interface
$nicId = $nic.Id


# Get the Bastion resources of the subscription and prompt user to select one
$bastions = Get-AzBastion
if ($bastions.Count -gt 1) {
    Write-Host "Multiple Azure Bastion resources found in the subscription:"
    for ($i=0; $i -lt $bastions.Count; $i++) {
        Write-Host "$($i+1): $($bastions[$i].Name)"
    }
    $selection = Read-Host "Enter the number of the Azure Bastion resource you want to use"
    $bastion = $bastions[$selection-1]
} else {
    $bastion = $bastions[0]
}

# Get the ID of the Bastion resource
$bastionId = $bastion.Id

# Get the virtual network of the VM and Bastion
$vmVnetId = ($nic.IpConfigurations.Subnet.Id -split "/subnets/")[0]
$bastionVnetId = ($bastion.IpConfigurations.Subnet.Id -split "/subnets/")[0]


# Print the resource IDs
Write-Host "VM ID: $vmId"
Write-Host "NIC ID: $nicId"
Write-Host "Bastion ID: $bastionId"
if ($vmVnetId -ne $bastionVnetId) {
    Write-Host "Virtual network of Bastion and VM are different"
    Write-Host "$vmVnetId"
}


$objectId = Read-Host "Enter object ID of the user or group you want to grant access to"
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Reader" -Scope $vmId
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Reader" -Scope $nicId
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Reader" -Scope $bastionId
if ($vmVnetId -ne $bastionVnetId) {
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Reader" -Scope $vmVnetId
}