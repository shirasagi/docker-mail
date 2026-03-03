FROM almalinux:8
LABEL maintainer="NAKANO Hideo <nakano@web-tips.co.jp>"

RUN echo "alias ll='ls -al'" >> ~/.bashrc

# Install packages
RUN dnf -y install procps
RUN dnf -y install postfix dovecot
RUN dnf clean all

#
# setup postfix
#

# master.cf: enable submission port
RUN sed -i 's/^#submission/submission/' /etc/postfix/master.cf

# main.cf: apply settings using postconf
RUN postconf -e "myhostname = ss001.example.jp" \
    && postconf -e "mydomain = example.jp" \
    && postconf -e "myorigin = \$mydomain" \
    && postconf -e "inet_interfaces = all" \
    && postconf -e "mynetworks_style = subnet" \
    && postconf -e "home_mailbox = Maildir/" \
    && postconf -e "header_checks = regexp:/etc/postfix/header_checks" \
    && postconf -e "virtual_mailbox_domains = example.jp" \
    && postconf -e "virtual_mailbox_base = /var/spool/virtual" \
    && postconf -e "virtual_mailbox_maps = hash:/etc/postfix/vmailbox" \
    && postconf -e "virtual_uid_maps = static:10000" \
    && postconf -e "virtual_gid_maps = static:10000" \
    && postconf -e "smtpd_sasl_auth_enable = yes" \
    && postconf -e "smtpd_sasl_type = dovecot" \
    && postconf -e "smtpd_sasl_path = private/auth" \
    && postconf -e "smtpd_client_restrictions = permit_mynetworks, permit" \
    && postconf -e "smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"

# header_checks: append rules
RUN printf "/^To:.*@example.jp/ OK\n/^To:.*/ REDIRECT sys@example.jp\n" >> /etc/postfix/header_checks

# Create mailuser and directory
RUN groupadd -g 10000 mailuser \
    && useradd -u 10000 -g mailuser -s /sbin/nologin mailuser \
    && mkdir -p /var/spool/virtual \
    && chown -R mailuser:mailuser /var/spool/virtual

# vmailbox setup
ADD ./assets/postfix/vmailbox /etc/postfix/vmailbox
RUN postmap /etc/postfix/vmailbox

# update aliases and chroot
RUN /usr/libexec/postfix/aliasesdb \
    && /usr/libexec/postfix/chroot-update

#
# setup dovecot
#

# 10-auth.conf: enable plaintext, domain, mechanisms, and passwd-file
RUN sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf \
    && sed -i 's/#auth_default_realm =/auth_default_realm = example.jp/' /etc/dovecot/conf.d/10-auth.conf \
    && sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain cram-md5/' /etc/dovecot/conf.d/10-auth.conf \
    && sed -i 's/^!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf \
    && sed -i 's/#!include auth-passwdfile.conf.ext/!include auth-passwdfile.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

# 10-mail.conf: mail location and quota plugin
RUN sed -i 's|#mail_location =|mail_location = maildir:/var/spool/virtual/%d/%n/Maildir|' /etc/dovecot/conf.d/10-mail.conf \
    && sed -i 's/#mail_plugins =/mail_plugins = quota/' /etc/dovecot/conf.d/10-mail.conf

# 10-master.conf: Postfix SASL auth socket (uncomment block and add user/group)
RUN sed -i '/#unix_listener \/var\/spool\/postfix\/private\/auth {/,/#}/ { s/^  #//; s/mode = 0666/mode = 0666\n    user = postfix\n    group = postfix/; }' /etc/dovecot/conf.d/10-master.conf

# 10-ssl.conf: disable SSL and comment out certificate paths
RUN sed -i 's/^ssl = required/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf \
    && sed -i 's/^ssl_cert =/#ssl_cert =/' /etc/dovecot/conf.d/10-ssl.conf \
    && sed -i 's/^ssl_key =/#ssl_key =/' /etc/dovecot/conf.d/10-ssl.conf

# 20-imap.conf: imap_quota plugin and connection limit
RUN sed -i 's/#mail_plugins = $mail_plugins/mail_plugins = $mail_plugins imap_quota/' /etc/dovecot/conf.d/20-imap.conf \
    && sed -i 's/#mail_max_userip_connections = 10/mail_max_userip_connections = 100/' /etc/dovecot/conf.d/20-imap.conf

# 90-quota.conf: quota rules and backend
RUN sed -i 's/#quota_rule = \*:storage=1G/quota_rule = *:storage=10M/' /etc/dovecot/conf.d/90-quota.conf \
    && sed -i 's/#quota_rule2 = Trash:storage=+100M/quota_rule2 = Trash:storage=+1M/' /etc/dovecot/conf.d/90-quota.conf \
    && sed -i 's/#quota = maildir:User quota/quota = maildir:User quota/' /etc/dovecot/conf.d/90-quota.conf

# auth-passwdfile.conf.ext: default fields
RUN sed -i 's|#default_fields =|default_fields = uid=mailuser gid=mailuser home=/var/spool/virtual/%d/%n|' /etc/dovecot/conf.d/auth-passwdfile.conf.ext

# Copy users list
ADD ./assets/dovecot/users /etc/dovecot/users

# EXPOSE 25
EXPOSE 143
EXPOSE 587

CMD /usr/sbin/postfix start && /usr/sbin/dovecot -F
