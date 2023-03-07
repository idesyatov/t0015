#!/usr/bin/env bash

SMTP_SERVER="smtp.server.ru"
SMTP_PORT="465"
USER="username"
PASSWORD="password"

TO="${1}"
MESSAGE="HELLO"

swaks -a \
  --port $SMTP_PORT \
  --server $SMTP_SERVER \
  --tls-on-connect \
  --timeout 40s \
  --from $USER \
  --auth LOGIN \
  --auth-user $USER \
  --auth-password $PASSWORD \
  --to $TO \
  --body $MESSAGE