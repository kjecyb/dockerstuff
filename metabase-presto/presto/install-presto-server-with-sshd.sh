#!/bin/bash
# sshd has to be running for presto-admin to do its thing
/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config -q &
echo sshd started
./presto-admin -i /root/.ssh/id_rsa server install latest