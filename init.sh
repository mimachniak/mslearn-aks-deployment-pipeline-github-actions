#!/bin/bash

echo "Defining variables..."
export RANDOM_NO=52563
export RESOURCE_GROUP_NAME=mslearn-gh-pipelines-$RANDOM_NO
export AKS_NAME=contoso-video
export ACR_NAME=ContosoContainerRegistry$RANDOM_NO

echo $RANDOM_NO
echo $RESOURCE_GROUP_NAME
echo $AKS_NAME
echo $ACR_NAME


echo "Searching for resource group..."
az group create -n $RESOURCE_GROUP_NAME -l eastus

echo "Creating cluster..."
az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $AKS_NAME \
  --node-count 1 \
  --enable-addons http_application_routing \
  --dns-name-prefix $AKS_NAME \
  --enable-managed-identity \
  --generate-ssh-keys \
  --node-vm-size Standard_B2s

echo "Obtaining credentials..."
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP_NAME

echo "Creating ACR..."
az acr create -n $ACR_NAME -g $RESOURCE_GROUP_NAME --sku basic
az acr update -n $ACR_NAME --admin-enabled true

export ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query "username" -o tsv)
export ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)

az aks update \
    --name $AKS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --attach-acr $ACR_NAME

export DNS_NAME=$(az network dns zone list -o json --query "[?contains(resourceGroup,'$RESOURCE_GROUP_NAME')].name" -o tsv)

sed -i '' 's+!IMAGE!+'"$ACR_NAME"'/contoso-website+g' kubernetes/deployment.yaml
sed -i '' 's+!DNS!+'"$DNS_NAME"'+g' kubernetes/ingress.yaml

echo "Installation concluded, copy these values and store them, you'll use them later in this exercise:"
echo "-> Resource Group Name: $RESOURCE_GROUP_NAME"
echo "-> ACR Name: $ACR_NAME"
echo "-> ACR Login Username: $ACR_USERNAME"
echo "-> ACR Password: $ACR_PASSWORD"
echo "-> AKS Cluster Name: $ACR_NAME"
echo "-> AKS DNS Zone Name: $DNS_NAME"
