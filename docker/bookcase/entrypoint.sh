#!/bin/bash

echo "---> Starting sshd on the slurmd..."
sudo /usr/sbin/sshd -e

cp -R /opt/home/student /home/student  
chmod 700 /home/student/.ssh
chmod 600 /home/student/.ssh/id_rsa
chmod 600 /home/student/.ssh/id_rsa.pub
chmod 600 /home/student/.ssh/authorized_keys
chmod 600 /home/student/.ssh/config

cd /home/student/
code-server --bind-addr 0.0.0.0:8088
