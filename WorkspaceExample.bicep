param workspaceName string
param location string
param serviceGroupId string
param scenarioName string = 'DnsOutage.v1'

// Deploy the Workspace
resource chaosWorkspace 'Microsoft.Chaos/workspaces@2025-09-01-preview' = {
    name: workspaceName
    location: location
    properties: {
        scope: serviceGroupId
        identity: {
          type: 'SystemAssigned'
        }
        tags: {}
    }
}

// Reference the DNS Outage Scenario that is created automatically in the Workspace
resource dnsScenario 'Microsoft.Chaos/workspaces/scenarios@2025-09-01-preview' existing = {
    name: '${chaosWorkspace.name}/${scenarioName}'
}

// Create a configuration for the DNS Outage Scenario
resource dnsScenarioConfig 'Microsoft.Chaos/workspaces/scenarios/configurations@2025-09-01-preview' = {
    name: '${chaosWorkspace.name}/${dnsScenario.name}/default'
    properties: {
        // For MVP, this is a shell resource.
        // Future versions may include duration, exclusions, etc.
    }
}
