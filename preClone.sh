#!/bin/bash
# Init
FILE="/tmp/out.$$"
GREP="/bin/grep"
#....
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
else
    # Check if required packages are installed.
    rpm -qa | grep -qw yum-utils || yum install -y yum-utils

    # Step 0: Stop logging processes.
    systemctl stop rsyslog
    systemctl stop auditd

    # Step 1: Remove old kernels.
    package-cleanup --oldkernels --count=1

    # Step 2: Clean out yum.
    yum clean all

    # Step 3: Force the logs to rotate & remove logs we don't need.
    logrotate –f /etc/logrotate.conf
    rm –f /var/log/*-???????? /var/log/*.gz
    rm -f /var/log/dmesg.old
    rm -rf /var/log/anaconda

    # Step 4: Truncate the audit logs (and other logs we want to keep placeholders for).
    cat /dev/null > /var/log/audit/audit.log
    cat /dev/null > /var/log/wtmp
    cat /dev/null > /var/log/lastlog
    cat /dev/null > /var/log/grubby
    cat /dev/null > /var/log/messages
    cat /dev/null > /var/log/secure

    # Step 5: Remove the udev persistent device rules.
    rm -f /etc/udev/rules.d/70*

    # Step 6: Remove the traces of the template MAC address and UUIDs.
    sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0

    # Step 7: Clean /tmp out.
    rm –rf /tmp/*
    rm –rf /var/tmp/*

    # Step 8: Remove the SSH host keys.
    rm –f /etc/ssh/*key*

    # Step 9: Remove the root user's shell history.
    rm -f ~root/.bash_history
    unset HISTFILE

    # Step 10: Remove the root user’s SSH history & kickstart configuration file.
    rm -rf ~root/.ssh/
    rm -f ~root/anaconda-ks.cfg
fi
