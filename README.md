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
