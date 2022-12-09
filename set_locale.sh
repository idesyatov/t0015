#!/usr/bin/env bash

sh -c cat << 'EOF' > /etc/locale.gen
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOF

locale-gen
