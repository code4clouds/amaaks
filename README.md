Prototyping DO NOT USE

# Requirements
Azure Ubuntu 18.04 VM

# Creation of VM Offer
- Create the Ubunut VM and log in
- Download the setup script
``` bash
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/vmoffer-setup.sh
sudo chmod +x ./setup.sh
 ./setup.sh
```
- Set cron to assure all Docker-Compose service are up
``` bash
sudo crontab -e
@reboot sleep 60 && cd /home/amaaks/harbor && docker-compose up -d
```
- Create a Harbor repository entry
- Seed Harbor using the replication feature by using your repository entry
- Make sure the replica reposity is maked as public in Harbor

# Testing

Clicking on the button below, will create the Managed Application definition to a Resource Group in your Azure subscription.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcode4clouds%2Famaaks%2Fmain%2Fazuredeploy.json)


``` bash
./ama-deploy.sh <your_azure_email>
```