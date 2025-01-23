#!/usr/bin/env bash

# Now mongodb reps blocked
# Use a socks5 proxy /etc/apt/apt.conf.d/proxy.conf

sudo apt update && sudo apt upgrade -y && \
sudo apt install dirmngr gnupg apt-transport-https software-properties-common ca-certificates curl -y && \
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - && \
echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
sudo apt-get update && sudo apt install mongodb-org -y && systemctl enable mongod --now && \
cat <<'EOF' > /etc/logrotate.d/mongodb 
# Default log rotation / compression keeps 1 year of logs.
/var/log/mongodb/*.log {
  daily
  rotate 6
  dateext
  copytruncate
  delaycompress
  compress
  notifempty
  extension gz
  sharedscripts
  missingok
}
EOF
