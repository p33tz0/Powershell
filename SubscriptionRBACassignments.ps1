<#
.SYNOPSIS
 This script will export all Role Assignement in your Azure Subscriptions.
 Will only export Role Assignments at the subscription level.

 This script is provided as is.

.NOTES
  Version:        1.0
  Author:         Petrus Savolainen
  Creation Date:  21-03-2023

.PARAMETER OutPutPath
Define Output Path for Excel file. Mandatory


.EXAMPLE
.\SubscriptionRBACassignments.ps1 -OutPutPath C:\temp  
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory
)

# Login to Azure
Connect-AzAccount

$CurrentContext = Get-AzContext

# Initialize an empty array to store the role assignments
$allRoleAssignments = @()


# Initialize an empty array to store the role assignments for the current subscription
$subscriptionRoleAssignments = @()

Write-Verbose "Running for all subscriptions in Tenant" -Verbose
$Subscriptions = Get-AzSubscription -TenantId $CurrentContext.Tenant.Id

# Loop through all subscriptions in the tenant
foreach ($subscription in $Subscriptions) {
    # Set the current subscription
    Set-AzContext -Subscription $subscription.Id

    # Get all role assignments at the subscription level
    Write-Verbose "Changing to Subscription $($Subscription.Name)" -Verbose
    $roleAssignments = Get-AzRoleAssignment -Scope /subscriptions/$($subscription.Id) | Where-Object { $_.Scope -eq "/subscriptions/$($subscription.Id)" }

    # Add the role assignments to the array and reorder the columns
    $subscriptionRoleAssignments += foreach ($roleAssignment in $roleAssignments) {
        [pscustomobject]@{
            DisplayName = $roleAssignment.DisplayName
            RoleDefinitionName = $roleAssignment.RoleDefinitionName
            SignInName = $roleAssignment.SignInName
            SubscriptionName = $subscription.Name
            ObjectType = $roleAssignment.ObjectType
            ObjectId = $roleAssignment.ObjectId
            Scope = $roleAssignment.Scope
            RoleAssignmentName = $roleAssignment.RoleAssignmentName
        }
    }
        # Add the subscription's role assignments to the hashtable
        $allRoleAssignments += @{$subscription.Name = $subscriptionRoleAssignments}

}
# Create a new Excel file and add a worksheet for each subscription's role assignments
$outputFile = Join-Path $OutputDirectory "sub_role_assignments.xlsx"

foreach ($subscriptionName in $allRoleAssignments.Keys) {
    $subscriptionRoleAssignments = $allRoleAssignments.$subscriptionName

    $subscriptionRoleAssignments | Export-Excel -Path $outputFile -WorksheetName $subscriptionName -TableName $subscriptionName -AutoSize -BoldTopRow
}

# Write verbose output
Write-Verbose "Role assignments at the resource group level for all subscriptions in the current tenant written to $($outputFile)..." -Verbose
