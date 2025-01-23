#!/usr/bin/env bash

USER="dev"

AUTHORIZED_KEYS="\
# access for operations
ssh-ed25519 Ki1E22Iss1YLmc2BKlydtaxyrD94Z8hX3vJiyUmoYgxJMXkleKJAK1MvV4tm7U0BnDha"

[[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1

useradd -m ${USER} && \
su -l ${USER} -c "cd /home/${USER} && mkdir -p .ssh && chmod 700 .ssh && touch ./.ssh/authorized_keys && \
chmod 600 ./.ssh/authorized_keys && \
cat << 'EOF' > ./.ssh/authorized_keys
${AUTHORIZED_KEYS}
EOF"

usermod --shell /bin/bash ${USER}

exit 0
