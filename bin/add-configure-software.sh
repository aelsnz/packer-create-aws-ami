#!/bin/bash -eux
#
# Description: 
#    This script is executed to install cloud-init, aws cli,  aws cloudwatch agent and a few aws tools depending on OS version
#    You can customize this to your requirements and install tools or other software
#    Ideally you do not want to install to much, as things might change and you then need to 
#    update the images again.  
#    

VER=`cat /etc/redhat-release`
ol5="Red Hat Enterprise Linux Server release 5"
ol6="Red Hat Enterprise Linux Server release 6"
ol7="Red Hat Enterprise Linux Server release 7"
ol8="Red Hat Enterprise Linux Server release 8"

case "$VER" in 
    "$ol5"*) 
             ## Oracle Linux 5 is old, have many restrictions, example old python etc.
             ## the steps below install python 2.7 to get aws cli going, but ideally later version required
             ##  
             cd /etc/yum.repos.d
             rm -rf *.repo 
             wget http://yum.oracle.com/public-yum-el5.repo
             yum -y upgrade
             cd /tmp
             wget http://dl.fedoraproject.org/pub/archive/epel/5/x86_64/epel-release-5-4.noarch.rpm   
             rpm -Uvh epel-release*rpm
            # Install python 2.7 to be used with aws cli 
             cd /tmp
             tar xzf Python-2.7.9.tgz
             cd Python-2.7.9
             ./configure --prefix=/usr/local
             make && make altinstall
             cd /tmp
             rm -rf /tmp/Python*
             yum -y --nogpgcheck install cloud-init
             curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
             unzip awscli-bundle.zip
             perl -p -i -e 's/env\ python/env\ python2.7/g' ./awscli-bundle/install
             ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
             rm -rf awscli-bundle*
             cd /tmp
             rm -rf /tmp/epel*
             rm -rf /tmp/aws*
             perl -p -i -e 's/enabled\=1/enabled\=0/g' /etc/yum.repos.d/epel.repo
             ## Add cloudwatch agent now - could be done as part of userdata as well to get latest
             wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
             rpm -U amazon-cloudwatch-agent.rpm
             rm -rf amazon-cloudwatch-agent.rpm 
             yum clean all
             ;;
    "$ol6"*) 
             cd /etc/yum.repos.d
             rm -rf *.repo
             wget http://yum.oracle.com/public-yum-ol6.repo
             yum -y upgrade
             cd /tmp
             yum -y --enablerepo=ol6_addons,ol6_software_collections install cloud-init cloud-utils-growpart unzip rh-python36
             yum clean all             
             echo "source scl_source enable rh-python36" > /etc/profile.d/enablepython36.sh 
             chmod a+x /etc/profile.d/enablepython36.sh
             # Enable python36 to instal awscli
             source scl_source enable rh-python36
             curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
             unzip awscli-bundle.zip
             ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
             rm -rf awscli-bundle*
             ## Add cloudwatch agent now - could be done as part of userdata as well to get latest
             wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
             rpm -U amazon-cloudwatch-agent.rpm
             rm -rf amazon-cloudwatch-agent.rpm
             cd 
             ;;
    "$ol7"*) 
             yum -y upgrade
             cd /tmp
             yum -y --enablerepo=ol7_addons install cloud-init cloud-utils-growpart python3 unzip
             yum clean all
             curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
             unzip awscli-bundle.zip
             ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
             rm -rf awscli-bundle*
             ## Add cloudwatch agent now - could be done as part of userdata as well to get latest
             wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
             rpm -U amazon-cloudwatch-agent.rpm
             rm -rf amazon-cloudwatch-agent.rpm
             cd
             ;;

    "$ol8"*) 
             yum -y upgrade
             cd /tmp
             yum -y --enablerepo=ol8_addons install cloud-init cloud-utils-growpart python3 unzip
             yum clean all
             curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
             unzip awscli-bundle.zip
             ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
             rm -rf awscli-bundle*
             ## Add cloudwatch agent now - could be done as part of userdata as well to get latest
             wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
             rpm -U amazon-cloudwatch-agent.rpm
             rm -rf amazon-cloudwatch-agent.rpm
             cd
esac                      


## Now update cloud-init, change the user name to be ec2-user
#
sed -i 's/name: cloud-user/name: ec2-user/g' /etc/cloud/cloud.cfg
sed -i 's/gecos: Cloud User/gecos: EC2 Default User/g' /etc/cloud/cloud.cfg

## lock the ec2-user account
#
passwd -l ec2-user

# Do some cleanup
# 
rm -rf /var/lib/cloud/instance/sem/*

## Adjust a few SSH Settings:
# disable DNS lookup will speed things up, make sure root login not allowed and no password authentication
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config


