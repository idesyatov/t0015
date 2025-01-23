#!/usr/bin/env bash

[[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1

TOKEN=""
BUCKET="s3_data"
URL="https://aws/"
UID=1000
GID=1000

sudo apt install -y s3fs 
echo "${TOKEN}" > /etc/.s3.${BUCKET} && chmod 600 /etc/.s3.${BUCKET}

! [[ -d /opt/s3_data/${BUCKET} ]] && sudo mkdir -p /opt/s3_data/${BUCKET} || echo "mount point dir exist"

s3fs ${BUCKET} /opt/s3_data/${BUCKET} -o passwd_file=/etc/.s3.${BUCKET} -ouid=${UID},gid=${GID},allow_other,mp_ umask=002 -o url=${URL} -o use_path_request_style

if ! grep -q "s3_data/${BUCKET}" /etc/fstab; then
    sudo echo "${BUCKET} /opt/s3_data/${BUCKET} fuse.s3fs _netdev,allow_other,use_path_request_style,url=${URL} 0 0" >> /etc/fstab
else 
	echo "already added fstab"
fi

exit 0
