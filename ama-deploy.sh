#!/bin/bash

azure_email=$1
userid=$(az ad user show --id $azure_email --query objectId --output tsv)
roleid=$(az role definition list --name Owner --query [].name --output tsv)
location="centralus"
resourceGroup="amaaks-amp-test"

az group create --name $resourceGroup --location "$location"

az managedapp definition create \
    --name "amaaks-test" \
    --display-name "Azure Manage Apps - AKS" \
    --description "A sample POC for AKS in Manage Apps" \
    --location "$location" \
    --resource-group "$resourceGroup" \
    --create-ui-definition @C:"createUiDefinition.json" \
    --main-template @C:"mainTemplate.json" \
    --lock-level None \
    --authorizations "$userid:$roleid"
#   --package-file-uri "https://github.com/code4clouds/amaaks/raw/main/amaaks.zip"
