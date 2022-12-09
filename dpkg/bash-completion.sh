#!/usr/bin/env bash


apt install bash-completion -y

if ! grep -q "bash_completion" /root/.bashrc; then
cat <<'EOF' >> /root/.bashrc

if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
EOF

else 
	echo "already added .bashrc"
fi

source ~/.bashrc
