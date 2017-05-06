#!/usr/bin/env bash
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
            
    # Update sources and install necessary packages
    yum update -y && yum install -y epel-release yum-utils

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

    # Step 3: Set SELinux to Permissive mode.
    printf "Checking SELinux status...\n"
    if [ $(getenforce) = "Enforcing" ]
    then
        setenforce "0" && printf "SELinux is now $(getenforce).\n"
    elif [ $(getenforce) = "Permissive" ]
    then
        printf "SELinux is already $(getenforce).\n"
    else
        printf "Could not determine SELinux status.\n"
    fi

    # Step 4: Force the logs to rotate & remove logs we don't need.
    logrotate -f /etc/logrotate.conf
    find $logDir -name "*-????????" -type f -delete
    find $logDir -name "dmesg.old" -type f -delete
    find $logDir -name "anaconda" -type f -delete

    # Step 5: Truncate the audit logs (and other logs we want to keep placeholders for).
    for f in "${logFiles[@]}"
    do
        if [ -f "$f" ]
        then
            cat /dev/null > "$f"
        else
            touch "$f"
        fi
    done

    # Done (for now!)
    printf "Boostrap process complete!"
    #printf "Restarting now..." && shutdown -r now