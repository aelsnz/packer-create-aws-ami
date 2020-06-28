#!/bin/bash -e
#
# DESCRIPTION:
#   This script can be used to build a specific vmdk disk image using packer for creating
#   an AWS AMI - see the README in the main folder for more details
#   Pre-requisites is that packer, virtualbox is installed and that the oracle linux software ISO images
#   are located in the software subfolder - for OL5 the Python 2.7 source file must be in the software folder as well
#
#   Example, to build the ol7 image, just run: 
#      ./build.sh -o ol7 -s3 demo_bucket_name -region us-east-1
#
#   Once done you can import into your AWS account
# 
# To enable bash Debugging, uncomment next line:
# set -x 
#

###########################################
#  Function to echo usage
###########################################
usage ()
{
  program=`basename $0`

cat <<EOF
Usage:
   ${program} all|ol5|ol6|ol7|ol8 -s3 <bucket_name> -region <region>

   Example:
      ${program} -o ol7 -s3 demo_bucket -region us-east-1

EOF

addLog "err."
addLog "============================="

exit 1
}

###########################################
#  Function to clean up....
###########################################
trap_err () {
   addLog '....'
   addLog 'Caught signal .... cleaning up...'  
   ## Placeholder
   addLog "done... exit"
   exit 999
}


###########################################
#  Function to setup environment
###########################################
setup_parameters ()
{
   # set the path to include possible locations for packer and aws cli
   export PATH=~/bin:/usr/local/bin:$PATH
   log=build.log
}


###########################################
#  Function to Add text to logfile
###########################################
addLog()
{
  echo ${1}
  echo "`date +%d-%h-%Y:%H:%M:%S` : ${1}" >> ${log}
}

###########################################
#  Function to build the images using packer - these can take time 10-20min per image
###########################################
build ()
{
   addLog "Building ${1}"
   if [ "${1}" == "all" ]; then

      packer build -force conf/packer-ol5.json
      packer build -force conf/packer-ol6.json
      packer build -force conf/packer-ol7.json
      packer build -force conf/packer-ol8.json
      find ./output >> ${log}
   else 
      packer build -force conf/packer-${1}.json
      ls -l output/${1}/* >> ${log}
   fi   
   addLog "Done."
}

###########################################
#  Function to upload the files to your S3 bucket 
#  remember to pass in your s3 bucket name and make sure 
#  that you have permission to run the s3 cp command to the region you want
#
###########################################
upload_image ()
{
   addLog "Upload file to s3:   aws s3 cp output/${v_option}/${v_option}-x86_64-base-disk001.vmdk s3://${s3_bucket}/   "
   aws s3 cp output/${v_option}/${v_option}-x86_64-base-disk001.vmdk s3://${s3_bucket}/  
   addLog "Done."
}

###########################################
#  Function to import file from s3 as AMI
###########################################
import_ami ()
{
  addLog "Import Start for ${v_option} image using region as ${region}"

  cp conf/aws-import.json conf/aws-import-tmp.json
  perl -p -i -e "s/IMPORT_DESCRIPTION/Custom\ ${v_option} Image/g" conf/aws-import-tmp.json
  perl -p -i -e "s/IMPORT_S3_BUCKET/${s3_bucket}/g" conf/aws-import-tmp.json
  perl -p -i -e "s/VMDK_DISK_NAME/${v_option}-x86_64-base-disk001.vmdk/g" conf/aws-import-tmp.json

  ## toDO - OL8 does not work that well on import-image, but import-snapshot does work
  #  examples commands 
  #  aws ec2 import-snapshot --description "Test ol8" --disk-container "file://aws-import-tmp-ol8.json"
  #  aws ec2 describe-import-snapshot-tasks --import-task-ids import-snap-.....
  # After above create image from snapshot, then you can create instance, update to UEK Kernel and you have OL8
  # bit of a work-around - but seem to work. 

  # Start the import process - this can take time
  aws ec2 import-image --region ${region} --disk-containers "file://conf/aws-import-tmp.json" | jq '.ImportTaskId' > /tmp/$$.taskid
  local taskId=`cat /tmp/$$.taskid | sed 's/\"//g'`

  # Next we monitor the process
  while true; do
      local taskDetail=`aws ec2 describe-import-image-tasks --import-task-ids ${taskId}`
      local taskStatus=`echo $taskDetail | jq '.ImportImageTasks[].Status'  | sed 's/\"//g' `
      
      # debug by logging taskDetail status checks
      echo $taskDetail >> $log

      if [ "${taskStatus}" == "completed" ]; then
        addLog "Import complete !"
        break
      elif [ "${taskStatus}" == "active" ]; then
         addLog "Import status - ${taskStatus}"
         addLog ".."
         sleep 60       
      else ## something wrong... 
         addLog "Import ending - ${taskStatus}"
         break
      fi
  done
  rm /tmp/$$.taskid
  addLog "Done."
}

###########################################
## Main Section
###########################################

trap trap_err SIGKILL SIGTERM SIGHUP SIGINT

## set environment
#
setup_parameters

## Start logging
addLog "======================="


## we need at least one argument
#
if test $# -lt 1
then
  addLog "Not enough input values.."
  usage
fi   

## read arguments and validate them
#
while test $# -gt 0
do
   case ${1} in
   -o)     ## read option to build all|ol5|ol6|ol7|ol8
           shift 
           v_option=${1}
           ;;  
   -region)  ## read region
           shift  
           region=${1}
           ;;           
   -s3)     ## read s3 bucket value
           shift
           s3_bucket=${1}
           ;;         
   -h)
           usage
           ;;
   *)      usage
           ;;
   esac
   shift
done


###
#  
case ${v_option} in  
  "all") 
         build all
         ;;
  "ol5") 
         build ol5
         ;;
  "ol6") 
         build ol6
         ;;
  "ol7") 
         build ol7
         ;;
  "ol8") 
         build ol8
       ;;   
esac

upload_image 
import_ami

addLog "All Done."
addLog "======================="