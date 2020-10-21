#!/bin/bash
az login --identity

az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID
az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID

az aks get-credentials --resource-group amaaksv2 --name amaaks --admin

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: registry-ca
  namespace: kube-system
type: Opaque
data:
  registry-ca: $(cat ./harbor/ca.crt | base64 -w 0 | tr -d '\n')
EOF

kubectl apply -f aks-harbor-ca-daemonset.yaml
kubectl create secret docker-registry amaaksregcred --docker-server=amaaks --docker-username=admin --docker-password=Harbor12345 --docker-email=someguy@code4clouds.com

# Deploy containers
kubectl apply -f kanary-deployment.yaml
kubectl apply -f kanary-service.yaml
