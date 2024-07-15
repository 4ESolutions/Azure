//***********************************************************************************************************************
//Parameters - Options Azure AD Join, Intune, Ephemeral disks etc
@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false
@description('Wheter to use emphemeral disks for VMs')
param ephemeral bool = false
@description('Declares whether Azure AD joined or not')
param AADJoin bool = false
@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

//***********************************************************************************************************************
//Parameters - Host Pool Settings
@description('Name for Host Pool.')
param hostPoolName string

@description('Domain that AVD Session Hosts will be joined to.')
param domainToJoin string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

@description('Name of resource group containing AVD HostPool')
param resourceGroupName string

@description('Friendly name of Desktop Application Group. This is shown under Remote Desktop client.')
param desktopName string

//***********************************************************************************************************************
//Parameters - DSC Parameters
param artifactsLocation string
param _artifactsLocationSASRef string

@description('Azure Tenant ID. Used for DSC scripts.')
@secure()
param AzTenantID string

@description('Name of the Application Group for DSC script.')
param appGroupName string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
@secure()
param appSecret string

@description('Parameter to determine if user assignment is required. If true defaultUsers will be used.')
param assignUsers string

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string

//***********************************************************************************************************************
//Parameters - Session Host VM Settings (OS, Disk, Networking)
@description('Location for all standard resources to be deployed into.')
param location string

@description('Prefix to use for Session Host VM build. Build will add the version details to this. E.g. AVD-PROD-11-0-x X being machine number.')
param vmPrefix string

@description('Required storage type for Session Host VM OS disk.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string

@description('The Windows version for the VM.')
@allowed([
'win11-22h2'
'win11-21h2'
'win11_23h2'
'win11-21h2-pro'
'win11-23h2-pro'
])
param OSVersion string = 'win11-23h2-pro'

@description('VM Publisher.')
@allowed([
'microsoftwindowsdesktop'
'MicrosoftWindowsServer'
])
param publisher string = 'microsoftwindowsdesktop'

@description('VM Offer.')
@allowed([
'WindowsServer'
'windows-11'
'windows-10'
])
param vmOffer string = 'windows-11'

@description('VM Size to be used for Session Host build. E.g. Standard_D2s_v3')
param vmSize string = 'Standard_D2s_v3'

@description('Is Disk Encryption needed.')
param diskEncryptionRequired bool = false

@description('Is Availability Set needed.')
param availabilitySetRequired bool = true

@description('KeyVault Resource ID for Disk Encryption.')
param keyVaultResourceId string

@description('KeyVault URI for Disk Encryption.')
param keyVaultUrl string

@description('KeyVault Key URI.')
param keyUrl string

@description('Administrator Login Username Domain Join operation.')
param administratorAccountUserName string

@description('Administrator Login Password Domain Join operation.')
@secure()
param administratorAccountPassword string

@description('Local Administrator Login Username for Session Hosts.')
param localAdministratorAccountUserName string = 'vmadmin'

@description('Administrator Login Password for Session Hosts.')
@secure()
param localAdministratorAccountPassword string

@description('Number of Session Host VMs required.')
param AVDnumberOfInstances int

@description('Current number of Session Host VMs. Populated automatically for upgrade build. Do not edit.')
param currentInstances int

param useExistingResources bool = true

@description('Resource Group containing the VNET to which to join Session Host VMs.')
param existingVNETResourceGroup string

@description('Name of the VNET that the Session Host VMs will be connected to.')
param existingVNETName string

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param existingSubnetName string

@description('Data Collection Rule Resource Id')
param DCRId string

param tagParams object = {
  Dept: 'L200'
  Environment: 'Production'
}

//***********************************************************************************************************************
//Variables - All
var subnetID = useExistingResources ? resourceId(existingVNETResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingSubnetName) : null
var avSetSKU = 'Aligned'
var networkAdapterPostfix = '-nic'

//***********************************************************************************************************************
//Resources - NICs
resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
}]

//***********************************************************************************************************************
//Resources - Availability Set
resource availabilitySet 'Microsoft.Compute/availabilitySets@2021-11-01' = if (availabilitySetRequired == true) {
  name: '${vmPrefix}-AV'
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
  sku: {
    name: avSetSKU
  }
}

//***********************************************************************************************************************
//Resources - VMs - Supports logic for Ephemeral Disks and Trusted Launch VMs
resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${vmPrefix}-AV')
    }
    osProfile: {
      computerName: '${vmPrefix}-${i + currentInstances}'
      adminUsername: localAdministratorAccountUserName
      adminPassword: localAdministratorAccountPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
        }
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmPrefix}-${i + currentInstances}-OS'
        managedDisk: {
          storageAccountType: ephemeral ? 'Standard_LRS' : vmDiskType
        }
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadOnly'
        diffDiskSettings: ephemeral ? {
          option: 'Local'
          placement: 'CacheDisk'
        } : null
      }
      imageReference: {
        //id: resourceId(sharedImageGalleryResourceGroup, 'Microsoft.Compute/galleries/images/versions', sharedImageGalleryName, sharedImageGalleryDefinitionname, sharedImageGalleryVersionName)
        //id: '/subscriptions/${sharedImageGallerySubscription}/resourceGroups/${sharedImageGalleryResourceGroup}/providers/Microsoft.Compute/galleries/${sharedImageGalleryName}/images/${sharedImageGalleryDefinitionname}/versions/${sharedImageGalleryVersionName}'
        publisher: publisher
        offer: vmOffer
        sku: OSVersion
        version: 'latest'
      }
      dataDisks: []
    }    
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}')
        }
      ]
    }
  }
  tags: tagParams
  dependsOn: [
    availabilitySet
    nic[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Domain Join Extension - Contains logic for AADJoin or AD Join
resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): if (AADJoin == true) {
  name: '${vmPrefix}-${i + currentInstances}/joindomain'
  location: location
  properties:  {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true    
  }  
  dependsOn: [
    vm[i]
  ]
}]

//***********************************************************************************************************************
//Resources - DSC Extensions
resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${artifactsLocation}dsc/Configuration.zip${_artifactsLocationSASRef}'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        HostPoolName: hostPoolName
        ResourceGroup: resourceGroupName
        ApplicationGroupName: appGroupName
        DesktopName: desktopName
        AzTenantID: AzTenantID
        AppID: appID
        AppSecret: appSecret
        AssignUsers: assignUsers
        DefaultUsers: defaultUsers
        vmPrefix: vmPrefix
      }
    }
  }
  dependsOn: [
    vm[i]
    joindomain[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Disk Encryption Set
resource AVDDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for i in range(0, AVDnumberOfInstances): if (diskEncryptionRequired == true) {
  name: '${vmPrefix}-${i + currentInstances}/diskencryptionset'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyEncryptionKeyURL: keyUrl
      KeyVaultURL: keyVaultUrl
      KeyVaultResourceId: keyVaultResourceId
      KekVaultResourceId: keyVaultResourceId
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
  dependsOn: [
    vm[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Azure Monitoring Agent - Replacing Microsoft Monitoring Agent
resource AzureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): if (monitoringAgent == true) {
    name: '${vmPrefix}-${i + currentInstances}/AzureMonitoringAgent'
    location: location
    properties: {
        publisher: 'Microsoft.Azure.Monitor'
        type: 'AzureMonitorWindowsAgent'
        typeHandlerVersion: '1.16'
        autoUpgradeMinorVersion: true
        enableAutomaticUpgrade: true
    }
    dependsOn: [
      vm[i]
      dscextension[i]
    ]
}]

//***********************************************************************************************************************
//Resources - DCR Rule Association
resource SessionHostDCRAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = [for i in range(0, AVDnumberOfInstances): {
    name: '${vmPrefix}-${i + currentInstances}-DCRAssc'
    scope: vm[i]
    properties: {
        dataCollectionRuleId: DCRId
    }
    dependsOn: [
        vm[i]
        dscextension[i]       
        AzureMonitorAgent[i]
    ]
}]
