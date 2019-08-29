export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
apt-get update
apt-get install -y osquery

apt-get install -y jq docker.io docker-compose
systemctl start docker
usermod -aG docker vagrant

curl -L https://github.com/grafana/loki/releases/download/v0.3.0/logcli_linux_amd64.gz -o - | \
  gunzip > /usr/local/bin/logcli
chmod +x /usr/local/bin/logcli
