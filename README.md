Prototyping DO NOT USE

# Requirements
Azure Ubuntu 18.04 VM

# Creation of VM Offer
- login
- Download the setup script
``` bash
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/setup.sh
```
- Set cron to assure all Docker-compose service are up
``` bash
sudo crontab -e
@reboot sleep 60 && cd /home/amaaks/harbor && docker-compose up -d
```
- Create a Harbor repository entry
- Seed Harbor using the replication feature by using your repository entry
