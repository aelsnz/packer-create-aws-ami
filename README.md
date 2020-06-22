# Description

This repository contains sample code to help you create your own AWS AMI images for Oracle Linux.

It is a work in progress - Oracle Linux 5,6 and 7 works, but 8 is still in progress.

There are community AMI versions available, but in some cases it might be better to build your 
own as you then know what is installed and how it is configured. 

*Oracle Linux 8* - AMI build process is still work in progress - the image-import fails with 
"ClientError: Unable to determine kernel version", but using snapshot-import works, but extra step to create image from snapshot 
This is on todo list.


Extra information can be found in the AWS online documentation here: 
*  https://docs.aws.amazon.com/vm-import/latest/userguide/vmimport-image-import.html


# Requirements

1.  You must have packer installed - https://www.packer.io/
    Keeping up to date with latest packer versions is highly recommended
2.  Download the Oracle Linux ISO images and place them in the "software" sub folder, example:

```
...
software/
├── OracleLinux-R5-U11-Server-x86_64.iso
├── OracleLinux-R6-U10-Server-x86_64.iso
├── OracleLinux-R7-U8-Server-x86_64.iso
├── OracleLinux-R8-U2-Server-x86_64.iso
├── Python-2.7.9.tgz
```

3.  Information about kickstart files

    Kickstart files is extremely useful for automating Linux installations.  An easy way to get a sample file is perform a quick install of your Linux distribution, example Oracle Linux in my examples, and you will find a file /root/anaconda-ks.cfg.  This file is a kickstart file of the installation you performed.  You can take this file, reuse it, and even modify to meet your needs.

    Everyone will have their view on creating "golden images" that can be used to build upon.  Some will try and keep it as small as possible, others will install almost everything they can.  There is no right or wrong, but the ideal is to know what you install and make sure it will  be used.  Installing stuff that is not needed just takes up space.  Ideally you want to keep the installations small, but make sure it has all the tools you use on regular basis installed - it just simplifies things and means you do not have to install these tools everytime you create a new instance from these iamges.  

    In case you are looking for more details on the kickstart files see example: 
    OL7 - https://docs.oracle.com/en/operating-systems/oracle-linux/7/install/ol7-kickstart-install-options.html
    OL8 - https://docs.oracle.com/en/operating-systems/oracle-linux/8/install/auto-ks.html#about-ks


    *Important:*
    *  Do not assign static IP address or HOSTNAME, make sure networking is enabled, but using DHCP
    *  Do not install the Oracle EUK Kernel - use the RedHat kernel during install, AMI creation, then install the Oracle Kernel - EUK

4.  Create vmimport role and assign policy to it.  You can find the policy documents in the conf/ subfolder
    * role-policy.json
    * trust-policy.json

    *Impornant:* Update the role policy document to use your specified s3 bucket name

    For more detail on this please see: https://docs.aws.amazon.com/vm-import/latest/userguide/vmie_prereqs.html#vmimport-role

    The example commands to run via the AWS cli is:

```
    aws iam create-role --role-name vmimport --assume-role-policy-document file://conf/trust-policy.json
    aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document file://conf/role-policy.json
```


# Create the images

*  You can either use the build.sh script provided, example:

```
./build.sh -o ol7 -s3 demo_bucket_name -region us-east-1
```

*OR*

*  You can just update the import-ol*.json file in config to use your s3 bucket and build the image, upload it to s3 and then import.  

Example commands for OL7

```
packer build -force packer-ol7.json 
aws s3 cp output/ol7/ol7-x86_64-base-disk001.vmdk s3://your_s3_bucket/ 
aws ec2 import-image --region us-east-1 --disk-containers "file://conf/import-ol7.json"
```

Notes:
*  The import command can take a bit of time, you can monitor it using the import task id
*  The build process can take time 10-20 min, depending on your system configuration.

Once done you will end up with the images in the output/ol* sub folders
Example:

```
$ tree output/ol7
output/ol7
├── ol7-x86_64-base-disk001.vmdk
└── ol7-x86_64-base.ovf
```

# Other useful information

Creating an encrypted password to be used in your kickstart files, you can make use of python

```
python -c 'import crypt; print (crypt.crypt("your password", crypt.mksalt()))'
```

Example:

```
[oracle@c5717c7ef4d1 ~]$ python -c 'import crypt; print (crypt.crypt("your password", crypt.mksalt()))'
$6$FUqMEdsHuNfXT0xR$qUOoqrVCloweZypBrCwr5vAH8q3mH0ipOzFAfCFR.9x0gOWx/AeYDYXYUh1JkghGBfy0z9rbVu/AgAaEbdliS1
```

Then in the kickstart file "ks.cfg" for the particular OS

```
...
rootpw  --iscrypted $6$FUqMEdsHuNfXT0xR$qUOoqrVCloweZypBrCwr5vAH8q3mH0ipOzFAfCFR.9x0gOWx/AeYDYXYUh1JkghGBfy0z9rbVu/AgAaEbdliS1
auth --enableshadow --passalgo=sha512 --kickstart
...
```