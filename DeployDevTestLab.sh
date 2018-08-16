# script to Create an Azure Key Vault for the DevTestLab


resourceGroupName=$1
resourceGroupLocation=$2
keyvaultName=$3

templateFilePath="./DevTest.json"
parameterFilePath="./DevTest.parameters.json"

dateToken=`date '+%Y%m%d%H%M'`
deploymentName="cloud5mins"$dateToken


#az login

# You can select a specific subscription if you do not want to use the default
# az account set -s SUBSCRIPTION_ID

if !( $(az group exists -g  $resourceGroupName) ) then
    echo "---> Creating the Resourcegroup: " $resourceGroupName
    az group create -g $resourceGroupName -l $resourceGroupLocation
else
    echo "---> Resourcegroup:" $resourceGroupName "already exists."
fi

# Checking for a KeyVault
searchKeyVault=$(az keyvault list -g $resourceGroupName --query "[?name=='$keyvaultName'].name" -o tsv )
lenResult=${#searchKeyVault}


if [ ! $lenResult -gt 0 ] ;then
    echo "---> Creating keyvault: " $keyvaultName
    az keyvault create --name $keyvaultName --resource-group $resourceGroupName --location $resourceGroupLocation --enabled-for-template-deployment true
else
    echo "---> The Keyvaul $keyvaultName already exists"
fi


echo "---> Populating KeyVault..."
az keyvault secret set --vault-name $keyvaultName --name 'vmPassword' --value 'cr@zySheep42!'


# Deploy the DevTest Lab

echo "---> Deploying..."
az group deployment create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFilePath --parameters $parameterFilePath --verbose

# Create the VMs using the formula created in the deployment

labName=$(az resource list -g cloud5mins --resource-type "Microsoft.DevTestLab/labs" --query [*].[name] --output tsv)
formulaName=$(az lab formula list -g $resourceGroupName  --lab-name $labName --query [*].[name] --output tsv)

echo "---> Creating VM(s)..."
az lab vm create --lab-name $labName -g  $resourceGroupName --name FrankSDevBox --formula $formulaName 
echo "---> done <---"
