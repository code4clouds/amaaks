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

sudo systemctl restart docker

## Configure Harber hostname and cert-key location
# cp harbor.yml.tmpl harbor.yml
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/harbor.yml
#  certificate: /etc/docker/certs.d/amaaks:443/amaaks.cert
#  private_key: /etc/docker/certs.d/amaaks:443/amaaks.key
sudo ./prepare
sudo docker-compose down -v
sudo docker-compose up -d
(crontab -l ; echo "@reboot sleep 60 && cd /home/amaaks/harbor && docker-compose up -d1")| crontab -

# Update docker to recognize the host
sudo cat > /etc/docker/daemon.json <<-EOF
{
    "insecure-registries" : [ "amaaks" ]
}
EOF
sudo mv daemon.json /etc/docker/daemon.json


# Download the containers
# Login
curl --cookie-jar cookie.txt 'https://40.69.185.20/c/login' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'DNT: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.80 Safari/537.36 Edg/86.0.622.43' \
  -H 'X-Harbor-CSRF-Token: H3zWo7cIC4H7fef8DyDkfjPqZXvUWoEwkoQ+HNlnIpcWuLXOWBM06GqJiFBhiMmruXrKKs5YKb5AmdkXcqxpKg==' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Origin: https://40.69.185.20' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://40.69.185.20/harbor/sign-in?redirect_url=%2Fharbor%2Fprojects' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: sid=65e4c4bc107d6eed739ba931bd5cab7e; _gorilla_csrf=MTYwMzI0MzMyOHxJa05qVW1waVpUaGlVREp0VWpsSEszTmljV2QwTVZseFVYSXhSV0ZCY1dsUE1HZ3pia00yZGt4VE56QTlJZ289fIkI5cxwOLIwL3W-5XPNSvsyYkKcW7uW8qhoqgjfX6F8' \
  --compressed \
  --insecure \
  --data-raw 'principal=admin&password=Harbor12345' 

# Create REgistry Endpoint
curl -b cookie.txt 'https://40.69.185.20/api/v2.0/registries' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept: application/json' \
  -H 'DNT: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.80 Safari/537.36 Edg/86.0.622.43' \
  -H 'X-Harbor-CSRF-Token: bt9YxcOVRt8S2QdosMLAk7k86XPc5768qVSiJycPTPNnGzuoLI55toMtaMTeau1GM6xGIsblFjJ7SUUsjMQHTg==' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://40.69.185.20' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://40.69.185.20/harbor/registries' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: _gorilla_csrf=MTYwMzI0MzMyOHxJa05qVW1waVpUaGlVREp0VWpsSEszTmljV2QwTVZseFVYSXhSV0ZCY1dsUE1HZ3pia00yZGt4VE56QTlJZ289fIkI5cxwOLIwL3W-5XPNSvsyYkKcW7uW8qhoqgjfX6F8; sid=d0f27f91a334ddecd4ef964682eceab6' \
  --data-binary '{"credential":{"access_key":"","access_secret":"","type":"basic"},"description":"","insecure":false,"name":"code4clouds","type":"docker-hub","url":"https://hub.docker.com"}' \
  --compressed \
  --insecure

# Make Repo Public
curl  -b cookie.txt 'https://40.69.185.20/api/v2.0/projects/2' \
  -X 'PUT' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept: application/json' \
  -H 'DNT: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.80 Safari/537.36 Edg/86.0.622.43' \
  -H 'X-Harbor-CSRF-Token: kJGwgMfG8WIRf0VDdfYXDWj0ckaFO+c7oyHywZnhMbeZVdPtKN3OC4CLKu8bXjrY4mTdF585T7VxPBXKMip6Cg==' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://40.69.185.20' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://40.69.185.20/harbor/projects/2/configs' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: _gorilla_csrf=MTYwMzI0MzMyOHxJa05qVW1waVpUaGlVREp0VWpsSEszTmljV2QwTVZseFVYSXhSV0ZCY1dsUE1HZ3pia00yZGt4VE56QTlJZ289fIkI5cxwOLIwL3W-5XPNSvsyYkKcW7uW8qhoqgjfX6F8; sid=ea529735329cc961664167b0bb494adf; harbor-lang=en-us' \
  --data-binary '{"metadata":{"public":"true","enable_content_trust":"false","prevent_vul":"false","severity":"low","auto_scan":"false","reuse_sys_cve_allowlist":"true"},"cve_allowlist":{"creation_time":"2020-10-18T05:34:49.078Z","id":1,"items":[],"project_id":2,"update_time":"2020-10-21T03:18:08.064Z","expires_at":null}}' \
  --compressed \
  --insecure

# Create Replica
  curl -b cookie.txt 'https://40.69.185.20/api/v2.0/replication/policies' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept: application/json' \
  -H 'DNT: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.80 Safari/537.36 Edg/86.0.622.43' \
  -H 'X-Harbor-CSRF-Token: wFy0oj88FwHlzvseNtKK7unc1wuJOfbPjslQVflaDdvJmNfP0CcoaHQ6lLJYeqc7Y0x4WpM7XkFc1LdeUpFGZg==' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://40.69.185.20' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://40.69.185.20/harbor/replications' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: _gorilla_csrf=MTYwMzI0MzMyOHxJa05qVW1waVpUaGlVREp0VWpsSEszTmljV2QwTVZseFVYSXhSV0ZCY1dsUE1HZ3pia00yZGt4VE56QTlJZ289fIkI5cxwOLIwL3W-5XPNSvsyYkKcW7uW8qhoqgjfX6F8; sid=d0f27f91a334ddecd4ef964682eceab6' \
  --data-binary '{"name":"code4clouds","description":"","src_registry":null,"dest_registry":{"id":1,"name":"code4clouds","description":"","type":"docker-hub","url":"https://hub.docker.com","token_service_url":"","credential":{"type":"basic","access_key":"","access_secret":""},"insecure":false,"status":"healthy","creation_time":"2020-10-18T05:34:04.572027Z","update_time":"2020-10-21T01:27:35.506767Z"},"dest_namespace":null,"trigger":{"type":"manual","trigger_settings":{"cron":""}},"enabled":true,"deletion":false,"override":false,"filters":[{"type":"name","value":"code4clouds/**"}]}' \
  --compressed \
  --insecure

# Execute Replica 
curl -b cookie.txt 'https://40.69.185.20/api/v2.0/replication/executions' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'Accept: application/json' \
  -H 'DNT: 1' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.80 Safari/537.36 Edg/86.0.622.43' \
  -H 'X-Harbor-CSRF-Token: fAyQmI6M4LVni/jm3lgovWOaKyZaRyb52/fXG7gvLXV1yPP1YZff3PZ/l0qw8AVo6QqEd0BFjncJ6jAQE+RmyA==' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://40.69.185.20' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://40.69.185.20/harbor/replications' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: _gorilla_csrf=MTYwMzI0MzMyOHxJa05qVW1waVpUaGlVREp0VWpsSEszTmljV2QwTVZseFVYSXhSV0ZCY1dsUE1HZ3pia00yZGt4VE56QTlJZ289fIkI5cxwOLIwL3W-5XPNSvsyYkKcW7uW8qhoqgjfX6F8; sid=d0f27f91a334ddecd4ef964682eceab6' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Cookie: sid=sid=ea529735329cc961664167b0bb494adf' \
  -H 'Content-Type: application/json' \
  --data-binary '{"policy_id":1}' \
  --compressed \
  --insecure



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
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/aks-install.sh
wget https://raw.githubusercontent.com/code4clouds/amaaks/main/aks-setup.sh

exit;
# Set cron to assure all Docker-compose service are up
# sudo crontab -e
# @reboot sleep 60 && cd /home/amaaks/harbor && docker-compose up -d

# Testing the registry by upload a container to amaaks
# docker login amaaks:443
#docker pull code4clouds/canarykontainer:1.1
#docker tag code4clouds/canarykontainer:1.1 amaaks:443/library/canarykontainer:1.1
#docker push amaaks:443/library/canarykontainer:1.1
#Setup replication for dockerhub (check the pictures on how to do this)
# docker pull amaaks:443/code4clouds/canarykontainer:1.2
