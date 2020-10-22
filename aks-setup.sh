#!/bin/bash
# az login --identity

# az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID
# az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID
if [ "$#" -ne 0 ]
  then 
    echo "Converting kubeconfig..."  
    echo $1 | base64 --decode > kube.config
    echo "Converted kubeconfig."
  else 
    echo "Getting kubeconfig using az get-creadentials..."
    az aks get-credentials --resource-group amaaksv2 --name amaaks --admin
    echo "Completed kubeconfig"
fi

cat <<EOF | kubectl apply  --kubeconfig=kube.config  -f -
apiVersion: v1
kind: Secret
metadata:
  name: registry-ca
  namespace: kube-system
type: Opaque
data:
  registry-ca: $(cat ./harbor/ca.crt | base64 -w 0 | tr -d '\n')
EOF

kubectl apply -f aks-harbor-ca-daemonset.yaml  --kubeconfig=kube.config 
kubectl create secret docker-registry amaaksregcred --docker-server=amaaks --docker-username=admin --docker-password=Harbor12345 --docker-email=someguy@code4clouds.com  --kubeconfig=kube.config 

# Deploy containers
kubectl apply -f kanary-deployment.yaml  --kubeconfig=kube.config 
kubectl apply -f kanary-service.yaml  --kubeconfig=kube.config 
