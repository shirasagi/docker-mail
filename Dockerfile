FROM centos
LABEL maintainer="NAKANO Hideo <nakano@web-tips.co.jp>"

RUN yum -y install patch postfix dovecot

#
# setup postfix
#
ADD ./assets/postfix/master.cf.patch /tmp/master.cf.patch
RUN cp -n /etc/postfix/master.cf /etc/postfix/master.cf.orig
RUN patch /etc/postfix/master.cf < /tmp/master.cf.patch

ADD ./assets/postfix/main.cf.patch /tmp/main.cf.patch
RUN cp -n /etc/postfix/main.cf /etc/postfix/main.cf.orig
RUN patch /etc/postfix/main.cf < /tmp/main.cf.patch

ADD ./assets/postfix/header_checks.patch /tmp/header_checks.patch
RUN cp -n /etc/postfix/header_checks /etc/postfix/header_checks.orig
RUN patch /etc/postfix/header_checks < /tmp/header_checks.patch

RUN groupadd -g 10000 mailuser
RUN useradd -u 10000 -g mailuser -s /sbin/nologin mailuser
RUN mkdir /var/spool/virtual
RUN chown -R mailuser:mailuser /var/spool/virtual

ADD ./assets/postfix/vmailbox /etc/postfix/vmailbox
RUN postmap /etc/postfix/vmailbox

RUN /usr/libexec/postfix/aliasesdb
RUN /usr/libexec/postfix/chroot-update

#
# setup dovecot
#
ADD ./assets/dovecot/10-auth.conf.patch /tmp/10-auth.conf.patch
RUN cp -n /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
RUN patch /etc/dovecot/conf.d/10-auth.conf < /tmp/10-auth.conf.patch

ADD ./assets/dovecot/10-mail.conf.patch /tmp/10-mail.conf.patch
RUN cp -n /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
RUN patch /etc/dovecot/conf.d/10-mail.conf < /tmp/10-mail.conf.patch

ADD ./assets/dovecot/10-master.conf.patch /tmp/10-master.conf.patch
RUN cp -n /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
RUN patch /etc/dovecot/conf.d/10-master.conf < /tmp/10-master.conf.patch

ADD ./assets/dovecot/10-ssl.conf.patch /tmp/10-ssl.conf.patch
RUN cp -n /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig
RUN patch /etc/dovecot/conf.d/10-ssl.conf < /tmp/10-ssl.conf.patch

ADD ./assets/dovecot/20-imap.conf.patch /tmp/20-imap.conf.patch
RUN cp -n /etc/dovecot/conf.d/20-imap.conf /etc/dovecot/conf.d/20-imap.conf.orig
RUN patch /etc/dovecot/conf.d/20-imap.conf < /tmp/20-imap.conf.patch

ADD ./assets/dovecot/90-quota.conf.patch /tmp/90-quota.conf.patch
RUN cp -n /etc/dovecot/conf.d/90-quota.conf /etc/dovecot/conf.d/90-quota.conf.orig
RUN patch /etc/dovecot/conf.d/90-quota.conf < /tmp/90-quota.conf.patch

ADD ./assets/dovecot/auth-static.conf.ext.patch /tmp/auth-static.conf.ext.patch
RUN cp -n /etc/dovecot/conf.d/auth-static.conf.ext /etc/dovecot/conf.d/auth-static.conf.ext.orig
RUN patch /etc/dovecot/conf.d/auth-static.conf.ext < /tmp/auth-static.conf.ext.patch

ADD ./assets/dovecot/users /etc/dovecot/users

EXPOSE 25
EXPOSE 143
EXPOSE 587

CMD /usr/sbin/postfix start && /usr/sbin/dovecot -F
