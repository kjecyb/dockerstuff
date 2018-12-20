#!/usr/bin/env bash
#
#   Because we need a docker container to run sshd and prestodb
#   we have to have a bash file as our ENTRYPOINT
#
echo "Extra params not used:" $@
set -e

# use backgrounding so that presto gets the signals when docker shutsdown
# See https://serverfault.com/questions/824975/failed-to-get-d-bus-connection-operation-not-permitted
# for why we are doing this here
#  -D don't detach
#  -e logs to stdout
#  
/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config -q &

/usr/lib/presto/bin/launcher run
