#!/bin/bash

# Requires Ubuntu host 18.04 DS2_V2 using hostname and user amaaks

# Install Docker https://docs.docker.com/engine/install/ubuntu/
sudo apt-get updates
sudo apt-get upgrade -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker amaaks

# Install Docker-Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install HARDBOR https://goharbor.io/docs/2.0.0/install-config/configure-https/
wget https://github.com/goharbor/harbor/releases/download/v2.1.0/harbor-offline-installer-v2.1.0.tgz
tar -xvf harbor-offline-installer-v2.1.0.tgz
cd harbor

openssl rand -out ~/.rnd -writerand ~/.rnd
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=US/ST=MA/CN=amaaks" -key ca.key -out ca.crt
openssl genrsa -out amaaks.key 4096
openssl req -sha512 -new  -subj "/C=US/ST=MA/CN=amaaks" -key amaaks.key -out amaaks.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=amaaks
EOF


openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in amaaks.csr \
    -out amaaks.crt

sudo mkdir -p /data/cert/
sudo cp amaaks.crt /data/cert/
sudo cp amaaks.key /data/cert/

openssl x509 -inform PEM -in amaaks.crt -out amaaks.cert
sudo mkdir -p /etc/docker/certs.d/amaaks:443
sudo cp amaaks.cert /etc/docker/certs.d/amaaks:443/
sudo cp amaaks.key /etc/docker/certs.d/amaaks:443/
sudo cp ca.crt /etc/docker/certs.d/amaaks:443
cat ca.crt >> registry.pem
cat amaaks.cert >> registry.pem
cat amaaks.key >> registry.pem

# Update docker to recognize the host
sudo cat > daemon.json <<-EOF
{
    "insecure-registries" : [ "amaaks" ]
}
EOF
sudo mv daemon.json /etc/docker/daemon.json

sudo systemctl restart docker

## Configure Harber hostname and cert-key location
# cp harbor.yml.tmpl harbor.yml
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/harbor.yml
#  certificate: /etc/docker/certs.d/amaaks:443/amaaks.cert
#  private_key: /etc/docker/certs.d/amaaks:443/amaaks.key
sudo ./prepare
#sudo docker-compose down -v
sudo docker-compose up -d
(crontab -l ; echo "@reboot sleep 60 && cd /home/amaaks/harbor && docker-compose up -d")| crontab -

# Configure Harbor

# Create Project
echo "Seeding Harbor..."
sleep 30 # warmup time for the Harbor Registry

curl -u "admin:Harbor12345" \
  -H "Content-Type: application/json" \
  -ki https://amaaks/api/v2.0/projects \
  --data-binary '{"project_name":"code4clouds","registry_id":null,"metadata":{"public":"true"},"storage_limit":-1}' \
  --compressed \
  --insecure

# Create Registry Endpoint
curl -u "admin:Harbor12345" \
  -H "Content-Type: application/json" \
  -ki https://amaaks/api/v2.0/registries \
  --data-binary '{"credential":{"access_key":"","access_secret":"","type":"basic"},"description":"","insecure":false,"name":"code4clouds","type":"docker-hub","url":"https://hub.docker.com"}' \
  --compressed \
  --insecure

# Create Replica
curl -u "admin:Harbor12345" \
  -H "Content-Type: application/json" \
  -ki https://amaaks/api/v2.0/replication/policies \
  --data-binary '{"name":"code4clouds","description":"","src_registry":{"id":1,"name":"code4clouds","description":"","type":"docker-hub","url":"https://hub.docker.com","token_service_url":"","credential":{"type":"","access_key":"","access_secret":""},"insecure":false,"status":"healthy","creation_time":"2020-10-21T05:48:49.305762Z","update_time":"2020-10-21T06:01:57.334003Z"},"dest_registry":null,"dest_namespace":null,"trigger":{"type":"manual","trigger_settings":{"cron":""}},"enabled":true,"deletion":false,"override":false,"filters":[{"type":"name","value":"code4clouds/**"}]}' \
  --compressed \
  --insecure

# Execute Replica 
curl -u "admin:Harbor12345" \
  -H "Content-Type: application/json" \
  -ki https://amaaks/api/v2.0/replication/executions \
  --data-binary '{"policy_id":1}' \
  --compressed \
  --insecure

sleep 30 # wait time to let harbor copy the images
echo "Seeding Harbor Completed..."
cd ..

# Install KubeCtl
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Install Az
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Copy the deployment files for the AKS configuration
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/aks-harbor-ca-daemonset.yaml 
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/kanary-deployment.yaml 
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/kanary-service.yaml 
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/aks-setup.sh
sudo chmod +x aks-setup.sh
./aks-setup.sh $1

exit;

# Testing the registry by upload a container to amaaks
#sudo docker login amaaks:443 -u admin
#sudo docker tag code4clouds/canarykontainer:1.1 amaaks:443/library/canarykontainer:1.1
#sudo docker push amaaks:443/library/canarykontainer:1.1
#Setup replication for dockerhub (check the pictures on how to do this)
#sudo docker pull amaaks:443/code4clouds/canarykontainer:1.2
