﻿@description('resource location')
param location string = 'westus'

@description('Name of the storage account')
param storageAccountName string = 'akylappstorage'

@description('Name of the function app')
param functionAppName string = 'akylfunc'

var managedIdentityName = '${functionAppName}-identity'
var appInsightsName = '${functionAppName}-appinsights'
var appServicePlanName = '${functionAppName}-appserviceplan'

var blobServiceUri = 'https://${storageAccountName}.blob.core.windows.net/'
var queueServiceUri = 'https://${storageAccountName}.queue.core.windows.net/'
var tableServiceUri = 'https://${storageAccountName}.table.core.windows.net/'
var queueName = 'queue'
var tableStorageName = 'table'

var storageOwnerRoleDefinitionResourceId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b'


resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
	name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
	  allowBlobPublicAccess: false
  }
}
resource storageQueuesService 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-04-01' = {
  name: queueName
  parent: storageQueuesService
  properties: {
	visibilityTimeout: '00:00:30'
	messageTimeToLive: '00:02:00'
	deadLetteringOnMessageExpiration: true
	maxDeliveryCount: 5
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-04-01' = {
  name: tableStorageName
  parent: tableService
}


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

resource storageOwnerPermission 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, functionAppName, storageOwnerRoleDefinitionResourceId)
  scope: storageAccount
  properties: {
	principalId: managedIdentity.properties.principalId
	roleDefinitionId: storageOwnerRoleDefinitionResourceId
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
	Application_Type: 'web'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
	name: 'Y1'
	tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {'${managedIdentity.id}': {}}
  }
  properties: {
	serverFarmId: appServicePlan.id
	siteConfig: {
	  appSettings: [
		{
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
		{
		  name: 'FUNCTIONS_EXTENSION_VERSION'
		  value: '~4'
		}
		{
		  name: 'FUNCTIONS_WORKER_RUNTIME'
		  value: 'dotnet'
		}
		{
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
		
		{
		  name: 'blobConnection__accountName'
		  value: storageAccountName
		}
		{
          name: 'blobConnection__serviceUri'
          value: blobServiceUri
        }
		{
          name: 'blobConnection__queueServiceUri'
          value: queueServiceUri
        }
		{
          name: 'blobConnection__tableServiceUri'
          value: tableServiceUri
        }
		
		{
		  name: 'blobConnection__credential'
		  value: 'managedidentity'
		}
		{
		  name: 'blobConnection__clientId'
		  value: managedIdentity.properties.clientId
		}
	  ]
	}
  }
}
