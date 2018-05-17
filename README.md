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
docker run --name mail -d mail
~~~
