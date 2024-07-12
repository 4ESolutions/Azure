# Introduction 
This project is to provide a Azure Virtual Desktop Deployment authored in BICEP currently.
Deployment is based on https://github.com/jamesatighe/AVD-BICEP and https://tighetec.co.uk/2021/07/07/deploy-azure-virtual-desktop-with-project-bicep/

This project is further enhanced to simplify the paramters and variables and utilise the Private EndPoints and SCaling Plans.

This AVD environment consists of following:

Key Vault with Disk EncryptionSet
Host Pool
Workspace
Application Group
Private EndPoints for HostPool and Workspace
Session Hosts VMs
Custom Configurations
- Custom Script Extensions and DSC to configure the environment. 
- This scripting performs the following actions.
- (If new deployment) Rename Desktop Application Group Friendly Name
- (If new deployment) Assign default users to Application Group
- Register Session Host VMs with Host Pool
Monitoring via Log Analytics Workspace

This deployment script can be used for either new environments or to add Session Host VMs to an existing deployment.

All BICEP files are included in the BICEP folder.

# Getting Started
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
You can either convert the BICEP into JSON ARM template files, or run the Azure deployment using the native BICEP files.

If you wish to convert to JSON format ensure BICEP is install on your machine and then run:

bicep build MainBuild.bicep

You can run the standard PowerShell New-AzResourceGroupDeployment or ***New command to intitate the deployment via:

New-AzSubscriptionDeployment -Location -TemplateFile

It is important to note the deployment scope for this deployment is Subscription not ResourceGroup. 
