@description('The existing resource you want to target in this experiment')
param targetName string

@description('Desired name for your Chaos Experiment')
param experimentName string

@description('Desired region for the experiment, targets, and capabilities')
param location string = resourceGroup().location

// Define Chaos Studio experiment steps for a basic Cosmos DB Offline/Online experiment
param experimentSteps array = [
  {
    name: 'Step1'
    branches: [
      {
        name: 'Branch1'
        actions: [
          {
            name: 'urn:csci:microsoft:cosmosdb:OfflineRegion/1.0'
            type: 'discrete'
            parameters: [
              {
                key: 'regionName'
                value: 'East US'
              }
            ]
            selectorId: 'Selector1'
          }
          {
            type: 'delay'
            duration: 'PT20M'
            name: 'urn:csci:microsoft:chaosStudio:TimedDelay/1.0'
          }
          {
            name: 'urn:csci:microsoft:cosmosdb:OnlineRegion/1.0'
            type: 'discrete'
            parameters: [
              {
                key: 'regionName'
                value: 'East US'
              }
            ]
            selectorId: 'Selector1'
          }
        ]
      }
    ]
  }
]

// Reference the existing Cosmos resource
resource cosmosdb 'Microsoft.DocumentDb/databaseAccounts@2023-04-15' existing = {
  name: targetName
}

// Deploy the Chaos Studio target resource to the Cosmos DB
resource chaosTarget 'Microsoft.Chaos/targets@2023-11-01' = {
  name: 'Microsoft-CosmosDB'
  location: location
  scope: cosmosdb
  properties: {}

  // Define the capability -- in this case, VM Shutdown
  resource chaosCapability 'capabilities' = {
    name: 'OfflineRegion-1.0'
  }

  resource chaosCapability2 'capabilities' = {
    name: 'OnlineRegion-1.0'
  }
}

// Define the role definition for the Chaos experiment
resource chaosRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: cosmosdb
  name: '230815da-be43-4aae-9cb4-875f7bd000aa'
}

// Define the role assignment for the Chaos experiment
resource chaosRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(cosmosdb.id, chaosExperiment.id, chaosRoleDefinition.id)
  scope: cosmosdb
  properties: {
    roleDefinitionId: chaosRoleDefinition.id
    principalId: chaosExperiment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deploy the Chaos Studio experiment resource
resource chaosExperiment 'Microsoft.Chaos/experiments@2024-01-01' = {
  name: experimentName
  location: location // Doesn't need to be the same as the Targets & Capabilities location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    selectors: [
      {
        id: 'Selector1'
        type: 'List'
        targets: [
          {
            id: chaosTarget.id
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    steps: experimentSteps
  }
}
