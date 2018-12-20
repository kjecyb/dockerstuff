#!/bin/bash
echo After docker starts, run the following in the container:
echo  "  " /root/presto.docker-entrypoint.sh
echo  "  "
echo  The Presto server will launch, the client can then be run:
echo  "  " /opt/presto/bin/presto-cli
echo  "  "
AWS_CONFIG_DIR=~/.aws
docker run --privileged -it  \
  --mount type=bind,src=${PWD}/presto/etc/jvm.config,dst=/etc/presto/jvm.config \
  --mount type=bind,src=${PWD}/presto/etc/config.properties,dst=/etc/presto/config.properties \
  --mount type=bind,src=${PWD}/presto/etc/node.properties,dst=/etc/presto/node.properties \
  --mount type=bind,src=${PWD}/presto/etc/catalog,dst=/etc/presto/catalog \
  --mount type=bind,src=${AWS_CONFIG_DIR},dst=/root/.aws \
  --entrypoint /bin/bash \
  jaskpresto.0.214
