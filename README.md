Prototyping DO NOT USE

# Requirements
Azure Ubuntu 18.04 VM

# Creation of VM Offer
- Create the Ubunut VM and log in
- Download the setup script
``` bash
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/setup.sh
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
