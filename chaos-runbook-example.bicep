@description('An existing Automation Account in the specified resource group')
param automationAccount string

@description('An existing Runbook within the Automation Account')
param runbookName string

@description('Desired region for the experiment & resources')
param location string = resourceGroup().location

// reference to the existing Automation Account
resource azureautoaccount 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: automationAccount
}

// role definition IDs for Automation Runbook Operator and Job Operator
var automationRunbookOperatorId = '5fb5aef8-1081-4b8e-bb16-9d5d0385bab5'
var automationJobOperatorId =  '4fe576fe-1146-4730-92eb-48519fa6bf9f'

// role assignment for Automation Runbook Operator and Job Operator
resource automationRunbookOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationRunbookOperatorId, toUpper(azureautoaccount.id), toUpper(chaosExperiment.id))
  scope: azureautoaccount
  properties: {
    principalId: chaosExperiment.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', automationRunbookOperatorId)
    principalType: 'ServicePrincipal'
  }
}

resource automationJobOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationJobOperatorId, toUpper(azureautoaccount.id), toUpper(chaosExperiment.id))
  scope: azureautoaccount
  properties: {
    principalId: chaosExperiment.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', automationJobOperatorId)
    principalType: 'ServicePrincipal'
  }
}

// Deploy the Chaos Studio experiment resource
resource chaosExperiment 'Microsoft.Chaos/experiments@2024-01-01' = {
  name: 'AzureAutomation-StartRunbook-V1v0'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    steps: [
      {
        name: 'Step1'
        branches: [
          {
            name: 'Branch1'
            actions: [
              {
                type: 'discrete'
                name: 'urn:csci:microsoft:automation:startRunbook/1.0'
                selectorId: 'Selector1'
                parameters: [
                  {
                    key: 'runbookName'
                    value: runbookName
                  }
                  {
                    key: 'runbookParameters'
                    value: '{"ResourceGroupName":"2025-carlsonr","VMName":"carlsonr-test-vm","SubscriptionId":"018bf144-3a6d-4c13-b1d3-d100a03adc6b"}'
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
    selectors: [
      {
        id: 'Selector1'
        type: 'List'
        targets: [
          {
            type: 'ChaosTarget'
            id: azureautoaccount.id
          }
        ]
      }
    ]
  }
}
