#!/bin/bash -eux
#
## Description:
#  This script is used to cleanup the system so that when it is started, we have a nice clean environment.
#
yum clean all
rm -f /root/anaconda-ks.cfg
rm -f /etc/ssh/ssh_host_*
rm -f /etc/resolv.conf
rm -f /root/.bash_history
rm -f /root/.ssh/known_hosts
rm -rf /var/tmp/*
rm -rf /tmp/*
rm -rf /var/lib/cloud/
rm -rf /var/log/cloud-init.log
rm -rf /var/log/cloud-init-output.log
rm -f /etc/udev/rules.d/70-persistent-net.rules

## Lets cleanup all logs in /var/log
for logfile in $(find /var/log -type f); do echo > $logfile; done

## Clean up network interfaces - remove hardware address and UUID
for ndev in $(ls /etc/sysconfig/network-scripts/ifcfg-*); do
  if [ "$(basename ${ndev})" != "ifcfg-lo" ]; then
    sed -i '/^HWADDR/d' ${ndev}
    sed -i '/^UUID/d' ${ndev}
  fi
done

