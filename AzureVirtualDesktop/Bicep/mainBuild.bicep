//***********************************************************************************************************************
//Core Deployment Parameters
targetScope = 'subscription'
param AzTenantID string = subscription().tenantId
param subscriptionID string = subscription().subscriptionId
param EnvironmentName string = 'avd'
param EnvironmentType string = 'dev'
param DeploymentScenario string = 'test01'
param artifactsLocation string
@secure()
param _artifactsLocationSASRef string
param AVDResourceGroup string = 'rg-avd-${EnvironmentType}-${DeploymentScenario}'
param workspaceLocation string

//***********************************************************************************************************************
//Core Build Options Update, NewBuild
@description('If true Host Pool, App Group and Workspace will be created. Default is to join Session Hosts to existing AVD environment')
param newBuild bool = true
@description('Combined with newBuild to ensure core AVD resources are not deployed when updating')
param update bool = false

//***********************************************************************************************************************
//Options Azure AD Join, Intune, Ephemeral disks etc
@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = true
@description('Wheter to use emphemeral disks for VMs')
param ephemeral bool = false
@description('Declares whether Azure AD joined or not')
param AADJoin bool = true
@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

//***********************************************************************************************************************
//Workspace
@description('Name of the AVD Workspace to used for this deployment')
param workspaceName string = 'ws-${DeploymentScenario}'
@description('List of application group resource IDs to be added to Workspace. MUST add existing ones!')
param applicationGroupReferences string

//***********************************************************************************************************************
//Application Group Settings
@description('Application Group Friendly name. This shows in Remote Desktop client.')
param appGroupFriendlyName string = '${DeploymentScenario} App Group'
@description('Friendly name of Desktop Application Group. This is shown under Remote Desktop client.')
param desktopName string = '${DeploymentScenario} Desktop'

//***********************************************************************************************************************
//Disk Encryption Settings - Key Vault etc
@description('Key Vault Name for Disk Encryption.')
param keyVaultName string = 'kv-avd-${DeploymentScenario}'

@description('Key Vault Disk Encryption SKU')
@allowed([
  'standard'
  'premium'
])
param keyVaultSKU string = 'standard'

@description('The JsonWebKeyType of the key to be created.')
@allowed([
  'EC'
  'EC-HSM'
  'RSA'
  'RSA-HSM'
])
param keyType string = 'RSA'

@description('Key Size.')
param keySize int = 2048

@description('Is Disk Encryption needed.')
param diskEncryptionRequired bool = false

//***********************************************************************************************************************
//Host Pool Settings
@description('Name for Host Pool.')
param hostPoolName string = 'hp-${DeploymentScenario}'

@description('Friendly Name of the Host Pool, this is visible via the AVD client')
param hostPoolFriendlyName string = '${DeploymentScenario} HostPool'

@description('Type used for Host Pool.')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Personal'

@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Automatic'

@description('Specify the maximum session limit for the Session Hosts.')
param maxSessionLimit int = 12

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Custom RDP properties to be applied to the AVD Host Pool.')
param customRdpProperty string

@description('Expiration time for the HostPool registration token. This is only used to configure the Host Pool. The VM deployment generates a token if required.')
param tokenExpirationTime string = dateTimeAdd(utcNow('u'), 'P30D')

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

@description('Domain that AVD Session Hosts will be joined to.')
param domain string

//***********************************************************************************************************************
//Session Host VM Settings
@description('Administrator Login UserName Domain Join operation.')
@secure()
param administratorAccountUserName string

@description('Administrator Login Password Domain Join operation.')
@secure()
param administratorAccountPassword string

@description('Local Administrator Login Username for Session Hosts.')
param localAdministratorAccountUserName string 

@description('Local Administrator Login Password for Session Hosts.')
@secure()
param localAdministratorAccountPassword string 

@description('Resource Group to deploy Session Host VMs into.')
param vmResourceGroup string = 'rg-avd-vms-${EnvironmentType}-${DeploymentScenario}'

@description('Azure Region to deploy VM Session Hosts into.')
param vmLocation string = 'australiaeast'

@description('VM Size to be used for Session Host build. E.g. Standard_D2s_v3')
param vmSize string

@description('Number of Session Host VMs required.')
param numberOfInstances int = 2

@description('Current number of Session Host VMs. Populated automatically for upgrade build. Do not edit.')
param currentInstances int = 0

@description('Prefix to use for Session Host VM build. Build will add the version details to this. E.g. AVD-PROD-11-0-x X being machine number.')
param vmPrefix string = 'avd-${DeploymentScenario}-vm'

@description('Required storage type for Session Host VM OS disk.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string

//param useExistingResources bool = true

//use if useExistingResources = true
@description('Resource Group containing the VNET to which to join Session Host VMs.')
param existingVNETResourceGroup string

@description('Name of the VNET that the Session Host VMs will be connected to.')
param existingVNETName string

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param existingSubnetName string

//use if useExistingResources = false
@description('Resource Group containing the VNET to which to join Session Host VMs.')
param vNetResourceGroup string = 'rg-net-${EnvironmentType}-${DeploymentScenario}'

@description('Name of the VNET that the Session Host VMs will be connected to.')
param vNetName string = 'vn-${EnvironmentType}-${EnvironmentName}-01'

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param subnetName string = 'default'

//***********************************************************************************************************************
//Shared Image Parameters
//@description('Is Image Trusted Launch?')
//param trustedLaunch bool = true

@description('Version name for image to be deployed as. I.e: 1.0.0')
param sharedImageGalleryVersionName string

//***********************************************************************************************************************
//DSC Parameters
@description('Parameter to determine if user assignment is required. If true defaultUsers will be used.')
param assignUsers string = 'true'

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
@secure()
param appSecret string

//***********************************************************************************************************************
//Used for Monitoring Module
@description('Subscription that Log Analytics Workspace is located in.')
param logworkspaceSub string

@description('Resource Group that Log Analytics Workspace is located in.')
param logworkspaceResourceGroup string = 'rg-${EnvironmentType}-la-001'

@description('Name of Log Analytics Workspace for AVD to be joined to.')
param logworkspaceName string = 'la-${EnvironmentType}-monitor-001'

@description('Log Analytics Workspace ID')
param workspaceID string

@description('Log Analytics Workspace Key')
param workspaceKey string

@description('Resource Group that Log Analytics Workspace is located in.')
param DCRResourceGroup string = 'rg-${EnvironmentType}-la-001'

param tagParams object = {
  Dept: 'ProjectName'
  Environment: EnvironmentType
}

//***********************************************************************************************************************
//Used for Private Endpoints for Hostpool and Workspace
param targetSubResource array

param HPprivateEndpointName string = 'pe-${hostPoolName}'
param WSprivateEndpointName string = 'pe-${workspaceName}'

param HPprivateDnsZoneName string = '${HPprivateEndpointName}-${targetSubResource[0]}.dns'
param WsFeedprivateDnsZoneName string = '${WSprivateEndpointName}-${targetSubResource[1]}.dns'
param WsGlobalprivateDnsZoneName string = '${WSprivateEndpointName}-${targetSubResource[2]}.dns'

param HPpvtEndpointDnsGroupName string = '${HPprivateEndpointName}-${targetSubResource[0]}/dns'
param WSFeedpvtEndpointDnsGroupName string = '${WSprivateEndpointName}-${targetSubResource[1]}/dns'
param WSGlobalpvtEndpointDnsGroupName string = '${WSprivateEndpointName}-${targetSubResource[2]}/dns'

param HPtargetSubResource array = ['${targetSubResource[0]}']
param WSFeedtargetSubResource array = ['${targetSubResource[1]}']
param WSGlobaltargetSubResource array = ['${targetSubResource[2]}']

param HPprivateLinkResource string  = '/subscriptions/${subscriptionID}/resourceGroups/${AVDResourceGroup}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
param WSprivateLinkResource string  = '/subscriptions/${subscriptionID}/resourceGroups/${AVDResourceGroup}/providers/Microsoft.DesktopVirtualization/workspaces/${workspaceName}'

param subnet string  = '/subscriptions/${subscriptionID}/resourceGroups/${AVDResourceGroup}/providers/Microsoft.Network/virtualNetworks/${existingVNETName}/subnets/${subnetName}'

//***********************************************************************************************************************
//Variables - All
var logAnalyticsResourceId = '/subscriptions/${logworkspaceSub}/resourceGroups/${logworkspaceResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${logworkspaceName}'

//***********************************************************************************************************************
//Modules - Resource Group, DCR, AVD Backplane, VMs
resource resourceGroupDeploy 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: DCRResourceGroup
}
module DCR './modules/DCR.bicep' = {
  name: 'DCR'
  scope: resourceGroup(DCRResourceGroup)
  params: {
      location: workspaceLocation
      monitoringAgent: monitoringAgent
      logAnalyticsResourceId: logAnalyticsResourceId
      workspaceID: workspaceID
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

module backPlane './modules/backPlane.bicep' = {
  name: 'backPlane'
  scope: resourceGroup(AVDResourceGroup)
  params: {
    location: workspaceLocation
    workspaceLocation: workspaceLocation
    logworkspaceSub: logworkspaceSub
    logworkspaceResourceGroup: logworkspaceResourceGroup
    logworkspaceName: logworkspaceName
    hostPoolName: hostPoolName
    hostPoolFriendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    appGroupFriendlyName: appGroupFriendlyName
    applicationGroupReferences: applicationGroupReferences
    loadBalancerType: loadBalancerType
    workspaceName: workspaceName
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    tokenExpirationTime: tokenExpirationTime
    maxSessionLimit: maxSessionLimit
    newBuild: newBuild
    update: update
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

module HostPoolPrivateEndpoint './modules/privateendpoint.bicep' = {
  name: 'HostPoolPrivateEndpoint'
  scope: resourceGroup(AVDResourceGroup)  
  params: {
    location: workspaceLocation
    targetSubResource: HPtargetSubResource
    vNetName: existingVNETName
    subnetName: subnetName
    privateEndpointName: HPprivateEndpointName
    privateDnsZoneName: HPprivateDnsZoneName
    pvtEndpointDnsGroupName: HPpvtEndpointDnsGroupName
    privateLinkResource: HPprivateLinkResource
    subnet: subnet
  }
  dependsOn: [
    backPlane
  ]
}

module WorkspaceFeedPrivateEndpoint './modules/privateendpoint.bicep' = {
  name: 'WorkspaceFeedPrivateEndpoint'
  scope: resourceGroup(AVDResourceGroup)  
  params: {
    location: workspaceLocation
    targetSubResource: WSFeedtargetSubResource
    vNetName: existingVNETName
    subnetName: subnetName
    privateEndpointName: WSprivateEndpointName
    privateDnsZoneName: WsFeedprivateDnsZoneName
    pvtEndpointDnsGroupName: WSFeedpvtEndpointDnsGroupName
    privateLinkResource: WSprivateLinkResource
    subnet: subnet
  }
  dependsOn: [
    backPlane
    HostPoolPrivateEndpoint
  ]
}

module WorkspaceGlobalPrivateEndpoint './modules/privateendpoint.bicep' = {
  name: 'WorkspaceGlobalPrivateEndpoint'
  scope: resourceGroup(AVDResourceGroup)  
  params: {
    location: workspaceLocation
    targetSubResource: WSGlobaltargetSubResource
    vNetName: existingVNETName
    subnetName: subnetName
    privateEndpointName: WSprivateEndpointName
    privateDnsZoneName: WsGlobalprivateDnsZoneName
    pvtEndpointDnsGroupName: WSGlobalpvtEndpointDnsGroupName
    privateLinkResource: WSprivateLinkResource
    subnet: subnet
  }
  dependsOn: [
    backPlane    
    HostPoolPrivateEndpoint
    WorkspaceFeedPrivateEndpoint
  ]
}

module diskEncryptionSet './modules/DiskEncryption.bicep' = if (diskEncryptionRequired) {
  name: 'DiskEncryptionSet'
  scope: resourceGroup(vmResourceGroup)
  params: {
    location: vmLocation
    keyVaultName: keyVaultName
    keyVaultSKU: keyVaultSKU
    keyType: keyType
    keySize: keySize
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

module VMswithLA './modules/VMs.bicep' = {
  name: '${sharedImageGalleryVersionName}-VMs'
  scope: resourceGroup(vmResourceGroup)
  params: {
    AzTenantID: AzTenantID
    location: vmLocation
    administratorAccountUserName: administratorAccountUserName
    administratorAccountPassword: administratorAccountPassword
    localAdministratorAccountUserName: localAdministratorAccountUserName
    localAdministratorAccountPassword: localAdministratorAccountPassword
    artifactsLocation: artifactsLocation
    _artifactsLocationSASRef: _artifactsLocationSASRef
    vmDiskType: vmDiskType
    vmPrefix: vmPrefix
    vmSize: vmSize
    currentInstances: currentInstances
    AVDnumberOfInstances: numberOfInstances
    existingVNETResourceGroup: existingVNETResourceGroup
    existingVNETName: existingVNETName
    existingSubnetName: existingSubnetName        
    hostPoolName: hostPoolName
    domainToJoin: domain
    ouPath: ouPath
    appGroupName: reference(extensionResourceId('/subscriptions/${subscriptionID}/resourceGroups/${AVDResourceGroup}', 'Microsoft.Resources/deployments', 'backPlane'), '2019-10-01').outputs.appGroupName.value
    appID: appID
    appSecret: appSecret
    assignUsers: assignUsers
    defaultUsers: defaultUsers
    desktopName: desktopName
    resourceGroupName: AVDResourceGroup
    DCRId: DCR.outputs.DCRId    
    tagParams: tagParams
    monitoringAgent: monitoringAgent
    ephemeral: ephemeral
    AADJoin: AADJoin
    intune: intune
    keyUrl: diskEncryptionRequired ? diskEncryptionSet.outputs.keyUrl : 'null'
    keyVaultResourceId: diskEncryptionRequired ? diskEncryptionSet.outputs.keyVaultResourceId : 'null'
    keyVaultUrl: diskEncryptionRequired ? diskEncryptionSet.outputs.keyVaultUrl : 'null' 
    diskEncryptionRequired: diskEncryptionRequired
  }
  dependsOn: [
    backPlane    
    HostPoolPrivateEndpoint
    WorkspaceFeedPrivateEndpoint
    WorkspaceGlobalPrivateEndpoint
    diskEncryptionSet
  ]
}
