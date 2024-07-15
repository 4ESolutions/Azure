# Variables
appName="Azure-KeyVault-Access"
role="Contributor" # You can change the role as needed
subscriptionId=$(az account show --query id -o tsv)

# Create an Azure AD application
app=$(az ad app create --display-name $appName --query appId -o tsv)
echo "Created Azure AD application with appId: $app"

# Create a service principal for the application
sp=$(az ad sp create --id $app --query objectId -o tsv)
echo "Created service principal with objectId: $sp"

# Assign a role to the service principal
az role assignment create --assignee $sp --role $role --scope /subscriptions/$subscriptionId
echo "Assigned $role role to the service principal"

# Output the service principal details
echo "Service Principal App ID: $app"
password=$(az ad sp credential reset --name $app --query password -o tsv)
echo "Service Principal Password: $password"
