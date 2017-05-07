#!/usr/bin/env bash
# Install and configure PowerDNS

if [[ $EUID -ne 0 ]];
then
   printf "This script must be run as root" 1>&2
   exit 1
else

    # Install prerequisites
    yum install -y epel-release yum-plugin-priorities &&

    # Configure repositories for all PDNS components in the stable branches
    curl -o /etc/yum.repos.d/powerdns-auth-40.repo https://repo.powerdns.com/repo-files/centos-auth-40.repo &&
    curl -o /etc/yum.repos.d/powerdns-dnsdist-11.repo https://repo.powerdns.com/repo-files/centos-dnsdist-11.repo &&
    curl -o /etc/yum.repos.d/powerdns-rec-40.repo https://repo.powerdns.com/repo-files/centos-rec-40.repo &&

    # Install PowerDNS Authoritative Server, PowerDNS Recursor, and dnsdist
    yum install -y pdns pdns-recursor dnsdist

fi