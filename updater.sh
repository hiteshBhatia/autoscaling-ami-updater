#!/bin/bash
set -e

DATE=`date +"%Y%m%d%H%M"`
new_lc_name="replica-architecture-sonyliv-$DATE"

function findLaunchConfig(){    
    _lc=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $1 --query AutoScalingGroups[*].LaunchConfigurationName --output text)
    echo $_lc
}

function findAMIinLaunchConfig(){    
    _lc_ami_id=$(aws autoscaling describe-launch-configurations --launch-configuration-names $1 --query LaunchConfigurations[*].ImageId --output text)
    echo $_lc_ami_id
}

function findAMIfromAutoscalingGroup(){
    _launch_configuration=$(findLaunchConfig $1)
    _current_ami_id=$(findAMIinLaunchConfig $_launch_configuration)
    echo $_current_ami_id
}

_file_name=$1
_changes=$3

if [ $# -gt 0 ] &&  [ -f "$_file_name" ];then
    
    source $_file_name
    _ami_id=$(findAMIfromAutoscalingGroup $AUTO_SCALING_GROUP)
    echo $_ami_id


    echo "3. Update AMI in example.json file $_ami_id packer-config.json"
    sed -i "s/$(grep source_ami packer-config.json | cut -d'"' -f4)/$_ami_id/g" packer-config.json

    echo "4. RUN PACKER and Fetch Id of new AMI and Pass a script to packer."
    packer build packer-config.json
    new_ami_id=$(packer build packer-config.json | tail -n 1 file | cut -d" " -f2)
    echo "$new_ami_id"


    echo "5. Create a new Launch config which is copy of existing launch config. but only AMI is updated"
    aws autoscaling create-launch-configuration --cli-input-json lc1.json --launch-configuration-name $new_lc_name

###### 
## DO NOT EXECUTE
## aws autoscaling update-auto-scaling-group --auto-scaling-group-name Replica-Architecture-SonyLIV --launch-configuration-name $new_lc_name
#####

else
     echo "bash updater.sh <config-file>"
#    echo "Usage updater.sh <source_variable> <packer_json_filename> <shell_script_to_packer_make_changes_in_instance> <json_file_to_create_new_launch_config>"
fi


