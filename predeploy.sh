#!/usr/bin/env bash

cp -vf ~/Projects/mysql-server/Dockerfile ~/hyperstor/mysql-server/
cp -vf ~/Projects/mysql-server/docker-compose.yml ~/hyperstor/mysql-server/
cp -vf ~/Projects/mysql-server/entrypoint.sh ~/hyperstor/mysql-server/
cp -vf ~/Projects/mysql-server/healthcheck.sh ~/hyperstor/mysql-server/
cp -vf ~/Projects/mysql-server/authorized_keys ~/hyperstor/mysql-server/
chmod 0755 ~/hyperstor/mysql-server/*.sh
chmod 0600 ~/hyperstor/mysql-server/authorized_keys

echo -e "\n$(date +%H:%M:%S) [ *** MySQL is ready for pod deployment *** ]\n"
