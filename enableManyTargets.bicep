@description('Array of existing virtual machine resources you want to target')
param vmTargets array = []

@description('Array of existing virtual machine scale set resources you want to target')
param vmssTargets array = []

@description('Desired region for the targets and capabilities')
param location string = resourceGroup().location

// Reference existing Virtual Machine resources
resource vms 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [for vm in vmTargets: {
  name: vm
}]

// Reference existing Virtual Machine Scale Set resources
resource vmssResources 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' existing = [for vmss in vmssTargets: {
  name: vmss
}]

// Deploy Chaos Studio target resources to the Virtual Machines
resource vmChaosTargets 'Microsoft.Chaos/targets@2024-01-01' = [for (vm, i) in vmTargets: {
  name: 'Microsoft-VirtualMachine'
  location: location
  scope: vms[i]
  properties: {}
}]

// Define the VM capabilities
resource vmShutdownCapabilities 'Microsoft.Chaos/targets/capabilities@2024-01-01' = [for (vm, i) in vmTargets: {
  name: 'Shutdown-1.0'
  parent: vmChaosTargets[i]
}]

// Deploy Chaos Studio target resources to the Virtual Machine Scale Sets
resource vmssChaosTargets 'Microsoft.Chaos/targets@2024-01-01' = [for (vmss, i) in vmssTargets: {
  name: 'Microsoft-VirtualMachineScaleSet'
  location: location
  scope: vmssResources[i]
  properties: {}
}]
  
// Define the VMSS capabilities
resource vmssShutdownCapabilities 'Microsoft.Chaos/targets/capabilities@2024-01-01' = [for (vmss, i) in vmssTargets: {
  name: 'Shutdown-2.0'
  parent: vmssChaosTargets[i]
}]


