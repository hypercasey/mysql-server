#!/usr/bin/env bash

mysql_status=`mysqladmin --defaults-extra-file=/var/lib/mysql-files/healthcheck.cnf ping`
sshd_status=`netstat -lntp | grep sshd | grep -v grep`

[[ `pgrep sshd` ]] && sshd_running=true || exec >&2 /usr/sbin/sshd
[[ `pgrep mysqld` ]] && mysqld_running=true

if [[ $sshd_running && $mysqld_running ]]; then
    [[ -n sshd_status ]] && echo >&2 "SSH Server: Healthy"
    [[ -n mysqld_status ]] && echo >&2 "MySQL Server: Healthy"
    [[ -z sshd_status || -z $mysql_status ]] && exit 1 || exit 0
else
    [[ -z sshd_status ]] && echo >&2 "SSH Server: Starting"
    [[ -z mysqld_status ]] && echo >&2 "MySQL Server: Starting"
    exit 1
fi