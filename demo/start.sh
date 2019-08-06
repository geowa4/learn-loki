#!/usr/bin/env bash

sudo cp ./osquery.conf /etc/osquery/osquery.conf
sudo cp ./osquery-incident-response.conf /usr/share/osquery/packs/incident-response.conf
sudo systemctl restart osqueryd

docker-compose pull
docker-compose up --force-recreate -d
