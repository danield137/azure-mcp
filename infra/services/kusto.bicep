targetScope = 'resourceGroup'

@minLength(3)
@maxLength(50)
@description('The base resource name.')
param baseName string = resourceGroup().name

@description('The location of the resource. By default, this is the same as the resource group.')
param location string = resourceGroup().location

@description('The tenant ID to which the application and resources belong.')
param tenantId string = '72f988bf-86f1-41af-91ab-2d7cd011db47'

@description('The client OID to grant access to test resources.')
param testApplicationOid string


resource kustoCluster 'Microsoft.Kusto/clusters@2024-04-13' = {
  name: baseName
  location: location
  sku: {
    name: 'Standard_D2_v2'
    tier: 'Standard'
    capacity: 2
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableStreamingIngest: true
    optimizedAutoscale: {
      isEnabled: false
      minimum: 1
      maximum: 1
      version: 1
    }
  }
}

resource kustoDatabase 'Microsoft.Kusto/clusters/databases@2024-04-13' = {
  parent: kustoCluster
  name: 'ToDoLists'
  kind: 'ReadWrite'
}

resource kustoPrincipalAssignment 'Microsoft.Kusto/clusters/principalAssignments@2024-04-13' = {
  parent: kustoCluster
  name: guid(kustoCluster.id, testApplicationOid)
  properties: {
    principalId: testApplicationOid
    principalType: 'App'
    role: 'AllDatabaseAdmin'
    tenantId: tenantId
  }
}


@description('The KQL script to initialize the test data.')
param initScript string = '.set-or-append ToDoList <| datatable(item: string) ["Hello World!"]'

resource kustoScript 'Microsoft.Kusto/clusters/databases/scripts@2024-04-13' = {
  parent: kustoDatabase
  name: 'init-data'
  properties: {
    scriptContent: initScript
    continueOnErrors: false
  }
}
