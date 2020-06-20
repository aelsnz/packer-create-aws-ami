#!/bin/sh -eux
#  Clean out the rest of the root disk
dd if=/dev/zero of=/zerofile bs=1M
rm -f /zerofile
sync

# todo - does anything need to happen to swap disk partition
# Note: Oracle Linux 5 does not have the cloud-utils-growpart option 
# 