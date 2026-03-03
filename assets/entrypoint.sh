#!/bin/bash
rm -f /var/run/rsyslogd.pid
/usr/sbin/rsyslogd
/usr/sbin/postfix start
/usr/sbin/dovecot
# wait for /var/log/maillog
touch /var/log/maillog
tail -F /var/log/maillog
