@description('The existing VMSS resource you want to target in this experiment')
param targetName string

@description('The existing Autoscale resource you want to target in this experiment')
param autoscaleName string

@description('Desired name for your Chaos Experiment')
param experimentName string

@description('Desired region for the experiment, targets, and capabilities')
param location string = resourceGroup().location

@description('Desired AZ to shut down VMSS instances in')
param zone string = '1'

// Define Chaos Studio experiment steps for a basic VMSS Shutdown experiment
param experimentSteps array = [
  {
    name: 'Step1'
    branches: [
      {
        name: 'AutoscaleBranch'
        actions: [
          {
            name: 'urn:csci:microsoft:autoscaleSettings:disableAutoscale/1.0'
            type: 'continuous'
            duration: 'PT10M'
            parameters: [
              {
                key: 'enableOnComplete'
                value: 'true'
              }
            ]
            selectorId: 'Selector2'
          }
        ]
      }
      {
        name: 'VMSSBranch'
        actions: [
          {
            name: 'urn:csci:microsoft:virtualMachineScaleSet:shutdown/2.0'
            type: 'continuous'
            duration: 'PT10M'
            parameters: [
              {
                key: 'abruptShutdown'
                value: 'true'
              }
            ]
            selectorId: 'Selector1'
          }
        ]
      }
    ]
  }
]
// Virtual Machine Scale Sets
// Reference the existing Virtual Machine Scale Sets resource
resource vm 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' existing = {
  name: targetName
}


// Deploy the Chaos Studio target resource to the Virtual Machine
resource chaosTarget 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-VirtualMachineScaleSet'
  location: location
  scope: vm
  properties: {}
  
  // Define the capability -- in this case, VM Shutdown
  resource chaosCapability 'capabilities' = {
    name: 'Shutdown-2.0'
  }
}

// Define the role definition for the Chaos experiment
resource chaosRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: vm
  // In this case, Virtual Machine Contributor role -- see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles 
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

// Define the role assignment for the Chaos experiment
resource chaosRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(vm.id, chaosExperiment.id, chaosRoleDefinition.id)
  scope: vm
  properties: {
    roleDefinitionId: chaosRoleDefinition.id
    principalId: chaosExperiment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Autoscale
resource autoscale 'Microsoft.Insights/autoscaleSettings@2022-10-01' existing = {
  name: autoscaleName
}

resource chaosAutoscaleTarget 'Microsoft.Chaos/targets@2022-10-01-preview' = {
  name: 'Microsoft-AutoscaleSettings'
  location: location
  scope: autoscale
  properties: {}

  resource chaosAutoscaleCapability 'capabilities' = {
    name: 'DisableAutoscale-1.0'
  }
}

resource chaosAutoscaleRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: autoscale
  name: '2cc479cb-7b4d-49a8-b449-8c00fd0f0a4b'
}


resource chaosAutoscaleRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(autoscale.id, chaosExperiment.id, chaosAutoscaleRoleDefinition.id)
  scope: autoscale
  properties: {
    roleDefinitionId: chaosAutoscaleRoleDefinition.id
    principalId: chaosExperiment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deploy the Chaos Studio experiment resource
resource chaosExperiment 'Microsoft.Chaos/experiments@2022-10-01-preview' = {
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
        filter: {
            type: 'Simple'
            parameters: {
                zones: [ 
                  zone
                ]
              }
          }
      }
      {
        id: 'Selector2'
        type: 'List'
        targets: [
          {
            id: chaosAutoscaleTarget.id
            type: 'ChaosTarget'
          }
        ]
      }
    ]
    startOnCreation: false // Change this to true if you want to start the experiment on creation
    steps: experimentSteps
  }
}