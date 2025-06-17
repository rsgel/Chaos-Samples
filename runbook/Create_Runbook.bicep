@description('Name of the Automation Account')
param automationAccountName string

@description('Name of the runbook to create')
param runbookName string = 'Shutdown-VM-Runbook'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the resource group containing the target VM')
param vmResourceGroupName string

@description('Name of the virtual machine to shut down')
param vmName string

@description('URI where the runbook PowerShell script is hosted')
param runbookScriptUri string

@description('SHA256 hash of the runbook script file (base64-encoded)')
param runbookScriptContentHash string

// Construct the full resource ID of the VM
var vmResourceId = resourceId(vmResourceGroupName, 'Microsoft.Compute/virtualMachines', vmName)

// 1. Create Automation Account with system-assigned identity
resource automationAccount 'Microsoft.Automation/automationAccounts@2024-10-23' = {
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
  }
}

// 2. Create and publish the PowerShell runbook
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2024-10-23' = {
  parent: automationAccount
  name: runbookName
  location: location
  properties: {
    runbookType: 'PowerShell'
    logVerbose: true
    logProgress: true
    description: 'Runbook that shuts down a specified VM'
    publishContentLink: {
      uri: runbookScriptUri
      contentHash: {
        algorithm: 'SHA256'
        value: runbookScriptContentHash
      }
      version: '1.0.0.0'
    }
  }
}

// 3. Assign Virtual Machine Contributor role at the VM scope
resource vmShutdownRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(vmResourceId, automationAccount.identity.principalId, '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
  scope: resourceId('Microsoft.Compute/virtualMachines', vmName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
    principalId: automationAccount.identity.principalId
  }
}
