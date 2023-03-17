mail/imap container for shirasagi development
====

This container is intended to use with shirasagi development.
Be carefule, this container is not for production.


# BUILD

run these commands:

~~~bash
docker build -t shirasagi/mail .
~~~

# RUN

run these commands:

~~~bash
docker run --name mail -d shirasagi/mail
~~~

Or if you want to access smtp or imap from your host processes, run these commands:

~~~bash
docker run --name mail -d -p 10143:143 -p 10587:587 shirasagi/mail
~~~

# UPLOAD to GitHub Container Registry

Before you upload your image, you should put a tag to your image.

1. Find the ID for the Docker image you want to tag.
  ~~~
  docker images
  ~~~
2. Tag your Docker image using the image ID and your desired image name and hosting destination.
  ~~~
  docker tag 38f737a91f39 ghcr.io/shirasagi/mail:latest
  ~~~

Then run these commands to upload the new container image to [GitHub Container Registry](https://github.com/orgs/shirasagi/packages):

~~~bash
export CR_PAT=YOUR_TOKEN
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
docker push ghcr.io/shirasagi/mail
~~~

YOUR_TOKEN is a personal access token created on the github your account page with "write:packages" scope, and USERNAME is your github account id.

# UPLOAD

run these commands to upload the new container image to [docker hub](https://hub.docker.com/):

~~~bash
docker login
docker push shirasagi/mail
~~~

# MANAGEMENT

## Configuration

You can see dovecot configuration via below command:

~~~bash
$ docker exec mail doveconf -n
# 2.2.36 (1f10bfa63): /etc/dovecot/dovecot.conf
# OS: Linux 4.9.125-linuxkit x86_64 CentOS Linux release 7.4.1708 (Core)  overlay
# Hostname: 081ec3ead4b7
auth_mechanisms = cram-md5
first_valid_uid = 1000
mail_location = maildir:/var/spool/virtual/%d/%n/Maildir
mail_plugins = quota
mbox_write_locks = fcntl
namespace inbox {
  inbox = yes
  location = 
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
  }
  prefix = 
}
passdb {
  args = scheme=CRYPT username_format=%u /etc/dovecot/users
  driver = passwd-file
}
plugin {
  quota = maildir:User quota
  quota_grace = 10%%
  quota_rule = *:storage=10M
  quota_rule2 = Trash:storage=+1M
}
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
}
ssl = no
ssl_cert = </etc/pki/dovecot/certs/dovecot.pem
ssl_key =  # hidden, use -P to show it
userdb {
  args = username_format=%u /etc/dovecot/users
  default_fields = uid=mailuser gid=mailuser home=/var/spool/virtual/%d/%n
  driver = passwd-file
}
protocol imap {
  mail_max_userip_connections = 100
  mail_plugins = quota imap_quota
}
~~~

## Users list

You can see users list via below command:

~~~bash
$ docker exec mail doveadm quota get -A
Username         Quota name Type    Value Limit                %
sys@example.jp   User quota STORAGE     0 10240                0
sys@example.jp   User quota MESSAGE     0     -                0
admin@example.jp User quota STORAGE     0 10240                0
admin@example.jp User quota MESSAGE     0     -                0
user1@example.jp User quota STORAGE     0 10240                0
user1@example.jp User quota MESSAGE     0     -                0
user2@example.jp User quota STORAGE     0 10240                0
user2@example.jp User quota MESSAGE     0     -                0
user3@example.jp User quota STORAGE     0 10240                0
user3@example.jp User quota MESSAGE     0     -                0
user4@example.jp User quota STORAGE     0 10240                0
user4@example.jp User quota MESSAGE     0     -                0
user5@example.jp User quota STORAGE     0 10240                0
user5@example.jp User quota MESSAGE     0     -                0
~~~
