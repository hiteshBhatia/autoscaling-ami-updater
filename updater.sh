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

_file_name=$1
_json_name=$2
_changes=$3
if [ $# -gt 3 ] &&  [ -f "$_file_name" ];then
    source $1
    echo $AUTO_SCALING_GROUP
    launch_configuration=$(findLaunchConfig $AUTO_SCALING_GROUP)
    echo "$launch_configuration"
    echo "2. Find Ami in Launch Config"
    current_ami_id=$(findAMIinLaunchConfig $launch_configuration)
    echo "$current_ami_id"
    echo "3. Update AMI in example.json file"
    sed -i "s/$(grep source_ami example_shel.json | cut -d'"' -f4)/$current_ami_id/g" example_shel.json 
    echo "4. RUN PACKER and Fetch Id of new AMI and Pass a script to packer."
    #packer build -t $_json_name
    new_ami_id=$(packer build example_shel.json | tail -n 1 file | cut -d" " -f2)
    echo "$new_ami_id"
    echo "5. Create a new Launch config which is copy of existing launch config. but only AMI is updated"
    aws autoscaling create-launch-configuration --cli-input-json lc1.json --launch-configuration-name $new_lc_name
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name Replica-Architecture-SonyLIV --launch-configuration-name $new_lc_name
else
    echo "Usage updater.sh <source_variable> <packer_json_filename> <shell_script_to_packer_make_changes_in_instance> <json_file_to_create_new_launch_config>"
fi


