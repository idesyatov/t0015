#!/usr/bin/env bash
# 0  *  *  *  *  /opt/scripts/ip_ban.sh >> /opt/scripts/ip_ban.log 2>&1


FLOOD_IP=(
$(netstat -anpt \
| awk '{print $5}' \
| cut -d: -f1 \
| sort \
| uniq -c \
| sort -n \
| grep -v '0.0.0.0' \
| grep -v '127.0.0' \
| awk '$1>30' \
| awk '{print $2}')
)

for i in "${FLOOD_IP[@]}"
do
  $(which iptables) -I INPUT -s $i -j DROP && echo "BAN: $i"
done
