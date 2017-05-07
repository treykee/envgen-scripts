#!/usr/bin/env bash
# Installs and configures 

if [[ $EUID -ne 0 ]];
then
   printf "This script must be run as root" 1>&2
   exit 1
else

    pg_hba_conf="/var/lib/pgsql/data/pg_hba.conf"

    # Install and configure PostgreSQL
    yum install -y postgresql-server postgresql-contrib
    
    # Create a new PostgreSQL database cluster
    postgresql-setup initdb
    
    # Create backup and modify pg_hba.conf to allow password authentication for PostgreSQL
    cp $pg_hba_conf /var/lib/pgsql/data/pg_hba.conf.original
    sed -i -e '\(host\)[ \t]+(all)[ \t]+(all)[ \t]+(\b(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b\/\d{1,2})[ \t]+(ident)/s/ident/md5/g' $pg_hba_conf
    sed -i -e '\(host\)[ \t]+\(all\)[ \t]+\(all\)[ \t]+\(::1\/\d{1,3}\)[ \t]+\(ident\)/s/ident/md5/g' $pg_hba_conf
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
fi