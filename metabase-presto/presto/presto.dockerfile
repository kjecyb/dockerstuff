# Initial dockerfile from: https://hub.docker.com/r/skame/presto/~/dockerfile/
#
# Where I finally found links to Presto Admin download:
# https://www.teradata.jp/Products/Open-Source/Presto/Downloads/Previous-Versions
#
# Someone who explicitly says where the catalog directory goes:
# https://github.com/prestodb/presto/issues/6593
# ... AND ... they are wrong.
# 

FROM centos:centos7

ENV PRESTO_VERSION 0.214

EXPOSE 22
EXPOSE 8080

WORKDIR /root
VOLUME /root/.aws
VOLUME /sys/fs/cgroup

RUN  yum -y update && \
  yum install -y sudo && \
  yum install -y strace

RUN yum install -y sed && \
  yum groupinstall -y "Development Tools" && \
  yum install -y java-1.8.0-openjdk && \
  yum install -y epel-release && \
  yum install -y wget python python-pip python-devel

# Install and configure sshd for running as a non-service (Can't do services in Docker with SystemD linux)
RUN \
  yum install -y openssh-server openssh-client && \
  /usr/bin/ssh-keygen -A && \
  mkdir /var/run/sshd && \
  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Make it so root can ssh back into this box without a login or a prompt
RUN \
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  chmod 700 ~/.ssh && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  for F in `ls /etc/ssh/*.pub`; do (echo localhost " " `cat $F`) >> ~/.ssh/known_hosts; done && \
  chmod 600 ~/.ssh/authorized_keys

RUN  pip install --upgrade pip==18.0
RUN  pip install awscli
RUN  pip install s3cmd
RUN  pip install python-magic

RUN mkdir /root/.prestoadmin && \
  mkdir /root/.prestoadmin/catalog

# Directories of catalog configuration
VOLUME /etc/presto/catalog

# Download presto-admin and use it to install Presto Server
# This will keep presto-admin and presto on the same page

ADD  prestoadmin/config.json /root/.prestoadmin/config.json

WORKDIR /opt/presto
RUN  curl -L -o presto-admin.tar.gz https://s3.us-east-2.amazonaws.com/starburstdata/presto-admin/2.5/prestoadmin-2.5-online.tar.gz && \
  tar xfz presto-admin.tar.gz && \
  rm presto-admin.tar.gz

WORKDIR /opt/presto/prestoadmin
RUN ./install-prestoadmin.sh

ADD install-presto-server-with-sshd.sh /opt/presto/prestoadmin/install-presto-server-with-sshd.sh
WORKDIR /opt/presto/prestoadmin
RUN chmod a+rx ./install-presto-server-with-sshd.sh && \
  ./install-presto-server-with-sshd.sh

# Also want the client
WORKDIR /opt/presto/bin
RUN  curl -o /opt/presto/bin/presto-cli https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar && \
  chmod a+rx /opt/presto/bin/presto-cli

WORKDIR /root
ADD presto.docker-entrypoint.sh .
RUN chmod a+rx presto.docker-entrypoint.sh

# Service state does not persist across RUN statements ... if you have dependent service (SSH in this case)
# your ENTRYPOINT must be a shell script
ENTRYPOINT ["/root/presto.docker-entrypoint.sh"]