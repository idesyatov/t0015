#!/usr/bin/env bash
# ./sh_addresses 192.168.1.0 1 254 

pingf()
{
  if ping -w 2 -q -c 1 "$1" > /dev/null; then 
    echo "IP $1 is busy"
  fi
}

if [ -n "$1" ]; then
  NET=$(echo "$1" | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){2}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
fi

NET=${NET:-$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d '/' | cut -f 1-3 -d .)}

H1=$(($2 + 0))
H2=$(($3 + 0))

if [ "$H1" -lt 1 ] || [ "$H1" -gt 254 ]; then
  H1=1
fi

if [ "$H2" -lt 1 ] || [ "$H2" -gt 254 ]; then
  H2=254
fi

I=$H1; while [ $I -le $H2 ]; do
  pingf "$NET.$I" &
  I=$(($I + 1))
done | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4
wait
