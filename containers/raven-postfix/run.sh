#!/bin/sh

echo "@$HOSTNAME root" > /etc/postfix/virtual

exec /usr/lib/postfix/master -d
