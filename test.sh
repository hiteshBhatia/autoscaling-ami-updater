sed -i "s/$($(grep ImageId lc1.json | cut -d'"' -f4)/$current_ami_id/g" lc1.json

