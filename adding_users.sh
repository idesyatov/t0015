#!/usr/bin/env bash


set -o errexit
set -o nounset
set -o pipefail


# Can be modified
declare -A user0=(
    [USERNAME]='user0'
    [AUTHORIZED_KEYS]='ssh-ed25519 $6$vxz7gJl3247WgRvZ$zTMPiOmKjJVq6MtdH20wBQ78Zi5BhrDWeYKrtcE9UJrjAZLI'
)

declare -A user1=(
    [USERNAME]='user1'
    [AUTHORIZED_KEYS]='ssh-ed25519 $6$vxz7gJl3247WgRvZ$zTMPiOmKjJVq6MtdH20wBQ78Zi5BhrDWeYKrtcE9UJrjAZLI'
)

declare -A user2=(
    [USERNAME]='user2'
    [AUTHORIZED_KEYS]='ssh-ed25519 $6$vxz7gJl3247WgRvZ$zTMPiOmKjJVq6MtdH20wBQ78Zi5BhrDWeYKrtcE9UJrjAZLI'
)

declare -A user3=(
    [USERNAME]='user3'
    [AUTHORIZED_KEYS]='ssh-ed25519 $6$vxz7gJl3247WgRvZ$zTMPiOmKjJVq6MtdH20wBQ78Zi5BhrDWeYKrtcE9UJrjAZLI'
)

USERS=(user0 user1 user2 user3)


# Better not to modify unnecessarily
[[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1

CREATE_USER() {
useradd -m ${1} && \
su -l ${1} -c "cd /home/${1} && mkdir -p .ssh && chmod 700 .ssh && touch ./.ssh/authorized_keys && \
chmod 600 ./.ssh/authorized_keys && \
cat << 'EOF' > ./.ssh/authorized_keys
${2}
EOF"
usermod --shell /bin/bash $1
}

ADDITION_SUDOERS() {
local users_str=$(echo $@ | sed "s/\s/, /g")
sh -c  "cat >> /etc/sudoers" <<EOT
User_Alias ADMINS = $users_str
ADMINS   ALL=(ALL)       NOPASSWD: ALL
EOT
}

MAIN() {
    for i in ${USERS[@]}; do
        ref=$(declare -p "$i")
        eval "declare -A data_ref="${ref#*=}

        if [[ ${#data_ref[@]} -gt 0 ]]; then
            CREATE_USER "${data_ref[USERNAME]}" "${data_ref[AUTHORIZED_KEYS]}"
            echo -e "Created ${data_ref[USERNAME]}"
        fi
    done
    ADDITION_SUDOERS "${USERS[@]}" 
}
MAIN
exit 0