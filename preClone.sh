#!/bin/bash
# Init
# Make sure only root can run our script
if [[ $EUID -ne 0 ]];
then
   printf "This script must be run as root" 1>&2
   exit 1
else
    # Set variables
    logServices=(rsyslog auditd)
    logDir="/var/log"
    logFiles=(/var/log/audit/audit.log /var/log/wtmp /var/log/lastlog /var/log/grubby /var/log/messages /var/log/secure)
    ifcfgFiles=( $(find /etc/sysconfig/network-scripts/ -type f | grep -E 'ifcfg-.*?[^lo]') )

            
    # Check if required packages are installed.
    rpm -qa | grep -qw yum-utils || yum install -y yum-utils

    # Step 0: Stop logging processes.
    for s in "${logServices[@]}"
    do
    ps auxw | grep "$s" | grep -v grep > /dev/null 2>&1
        if [ $? != 0 ]
        then
            printf "Stopping $s && service stop $s"
        else
            printf "$s is already stopped"'!\n'
        fi
    done

    # Step 1: Remove old kernels.
    package-cleanup -y --oldkernels --count=1

    # Step 2: Clean out yum.
    yum clean all

    # Step 3: Force the logs to rotate & remove logs we don't need.
    logrotate -f /etc/logrotate.conf
    find $logDir -name "*-????????" -type f -delete
    find $logDir -name "dmesg.old" -type f -delete
    find $logDir -name "anaconda" -type f -delete

    # Step 4: Truncate the audit logs (and other logs we want to keep placeholders for).
    for f in "${logFiles[@]}"
    do
        if [ -f "$f" ]
        then
            cat /dev/null > "$f"
        else
            touch "$f"
        fi
    done

    # Step 5: Remove the udev persistent device rules.
    if [[ -f /etc/udev/rules.d/70* ]]
    then
        rm -f "/etc/udev/rules.d/70*"
    else
        printf "No udev persistent device rules exist\n" >&2
    fi

    # Step 6: Remove the traces of the template MAC address and UUIDs.
    if [ ifcfgFiles ]
    then
        for f in "${ifcfgFiles[@]}"
        do
            sed -i '/^(HWADDR|UUID)=/d' "$f"
        done
    else
        printf "No virtual network adapter MAC address templates exist\n" >&2
    fi

    # Step 7: Clean /tmp out.
    rm -rf /tmp/* &>/dev/null
    rm -rf /var/tmp/* &>/dev/null

    # Step 8: Remove the SSH host keys.
    rm -f /etc/ssh/*key* >&2

    # Step 9: Remove the root user's shell history.
    rm -f ~root/.bash_history
    history -c
    unset HISTFILE

    # Step 10: Remove the root user’s SSH history & kickstart configuration file.
    rm -rf ~root/.ssh/
    rm -f ~root/anaconda-ks.cfg
fi