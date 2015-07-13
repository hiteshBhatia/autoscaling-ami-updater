AUTO_SCALING_GROUP=Replica-Architecture-SonyLIV
JSON_AMI_ID=$(cat example_shel.json | grep source_ami | cut -d'"' -f4)
#sudo apt-get install sysvbanner
