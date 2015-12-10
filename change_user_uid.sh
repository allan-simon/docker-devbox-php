#!/bin/bash
usermod -u $HOST_USER_UID vagrant
chown -R vagrant /home/vagrant
if  test -z "$@" ; then
    /sbin/my_init
else 
    exec "$@"
fi
