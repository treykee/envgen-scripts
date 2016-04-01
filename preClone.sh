#!/bin/bash
# Init
# Make sure only root can run our script
if [[ $EUID -ne 0 ]];
then
   echo "This script must be run as root" 1>&2
   exit 1
else
    # Set variables
    logDir="/var/log"
    logFiles=($logDir/audit/audit.log $logDir/wtmp $logDir/lastlog $logDir/grubby $logDir/messages $logDir/secure)
    
    # Check if required packages are installed.
    rpm -qa | grep -qw yum-utils || yum install -y yum-utils

    # Step 0: Stop logging processes.
    systemctl stop rsyslog
    service auditd stop

    # Step 1: Remove old kernels.
    package-cleanup --oldkernels --count=1

    # Step 2: Clean out yum.
    yum clean all

    # Step 3: Force the logs to rotate & remove logs we don't need.
    logrotate -f /etc/logrotate.conf
    rm -f $logDir/*-???????? $logDir/*.gz
    rm -f $logDir/dmesg.old
    rm -rf $logDir/anaconda

    # Step 4: Truncate the audit logs (and other logs we want to keep placeholders for).
    for f in "${logFiles[@]}";
    do
        if [ -f "$f" ];
        then
            cat /dev/null > "$f"
        else
            touch "$f"
        fi
    done

    # Step 5: Remove the udev persistent device rules.
    for file in /etc/udev/rules.d/70*
    do
        if [ -f "$file" ]
        then
            rm -f /etc/udev/rules.d/70*
        break
        fi
    done

    # Step 6: Remove the traces of the template MAC address and UUIDs.
    if [ -f "/etc/sysconfig/network-scripts/ifcfg-eth0" ];
    then
        sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
    else
        echo "File does not exist" >&2
    fi

    # Step 7: Clean /tmp out.
    rm -rf /tmp/*
    rm -Frf /var/tmp/*

    # Step 8: Remove the SSH host keys.
    rm -f /etc/ssh/*key*

    # Step 9: Remove the root user's shell history.
    rm -f ~root/.bash_history
    unset HISTFILE

    # Step 10: Remove the root user’s SSH history & kickstart configuration file.
    rm -rf ~root/.ssh/
    rm -f ~root/anaconda-ks.cfg
fi