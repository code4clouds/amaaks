Prototyping DO NOT USE

# Requirements
Azure Ubuntu 18.04 VM

# Creation of VM Offer
- Create an Ubuntu VM and log in
- Download the setup script
``` bash
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/vmoffer-setup.sh
cat ./vmoffer-setup.sh | base64 -w 0 # to use for script for VM custom extension script (optional)
sudo chmod +x ./vmoffer-setup.sh
 ./vmofffer-setup.sh
```

- Create a Harbor repository entry
- Seed Harbor using the replication feature by using your repository entry
- Make sure the replica reposity is maked as public in Harbor
- Generalize
- Create an image for internal deployments or VM Offer (if targeting the Azure Marketplace) by generalizing the VM
``` bash
sudo waagent -deprovision+user --force
sudo waagent -force -deprovision+user && export HISTSIZE=0 && sync
logout
```
- Deallocate the VM
``` bash
 az vm deallocate --resource-group amaaks --name amaaks
 az vm generalize --resource-group amaaks --name amaaks
 az image create --resource-group amaaks --name amaaks --source amaaks
 ```
- Create Snapshot
- Add the image to the image gallery
- Add the image gallery to the IAM of the resource group.


## Plain Ubbuntu Image VM
``` bash
 base64 -w 0 vmoffer-fullscript.sh > vmoffer-fullscript.sh.b64
```
Add the out put to the template under "vm-script"

# Testing

Clicking on the button below, will create the Managed Application definition to a Resource Group in your Azure subscription.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcode4clouds%2Famaaks%2Fmain%2Fazuredeploy.json)


``` bash
./ama-deploy.sh <your_azure_email>
```

The output will container the K8s kubeconf copy it to a file (e.g. kubeconfig.b64) then decode it and move it to your home directory.
``` 
 cat kubeconfig.b64 | base64 --decode > ~/.kube/config
 ```
