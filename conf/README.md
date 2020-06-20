# Description

All the configuration files are located in this conf sub folder.
These files include

1.  Packer build configuration files - naming is packer-ol*.json   (* is the linux version exampmle 5,6,7 or 8)
2.  The import json structure that is used to import into AWS:
    * aws-import.json   (this is a generic file that can be used with the "build.sh" script in the base folder)
    * import-oel*.json  (these are individual json files you can use to start import process)

3.  The role and trust policy documents that is required to perform the import of the images into AWS to create the AMI.
    * For more detail also see - https://docs.aws.amazon.com/vm-import/latest/userguide/vmimport-image-import.html

