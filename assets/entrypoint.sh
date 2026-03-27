#!/bin/bash

# postfix log
touch /var/log/maillog

# dovecot log
touch /var/log/maillog.log
touch /var/log/dovecot.log

tail -f /var/log/dovecot.log /var/log/maillog &
/usr/sbin/postfix start && /usr/sbin/dovecot -F
#tail -f /dev/null
