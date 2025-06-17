<#
.SYNOPSIS
  Shuts down a specified Azure VM using a managed identity.

.PARAMETER ResourceGroupName
  The name of the resource group containing the VM.

.PARAMETER VMName
  The name of the VM to shut down.

.PARAMETER SubscriptionId
  The subscription ID where the VM lives.
#>

param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $VMName,

    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId
)

# Prevent persisting context or credentials
Disable-AzContextAutosave -Scope Process

# Authenticate using the system-assigned managed identity
Connect-AzAccount -Identity

# Option A: set your default context
$AzureContext = Set-AzContext -SubscriptionId $SubscriptionId

# Attempt to stop the VM
try {
    Write-Output "Stopping VM '$VMName' in subscription '$SubscriptionId', resource group '$ResourceGroupName'..."
    Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force -DefaultProfile $AzureContext -ErrorAction Stop
    Write-Output "Shutdown command sent successfully."
}
catch {
    Write-Error "Failed to stop VM '$VMName': $_"
}
