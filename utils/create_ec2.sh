#!/bin/bash

# source create_subnet.sh
# source create_sg.sh

source create_vpc.sh

# creates an ec2 instance in a vpc
create_ec2_instance() {
	local key=$1
	local ami_id=$2
	local subnet=$2
	local ports_string=$2

	# create the vpc
	create_vpc $ports_string $subnet

	# create ec2 instance in the vpc
	aws ec2 run-instances \
		--image-id $ami_id \
		--count 1 \
		--instance-type t2.micro \
		--key-name $key \
		--subnet-id $subnet_id \
		--security-group-ids $security_group_ids \
		&& echo "created an ec2 instance" || exit 1
}

subnet_id=$1
sg_id=$2

if [ -z "$subnet_id" ]; then
    echo "Invalid argument is provided."
    return 1
else
    # get vpc_id from subnet
    subnet_vpc_id=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].VpcId' --output text 2>/dev/null)

    # cleck for blank case
    if [ -z "$sg_id" ]; then
        echo "Invalid argument is provided"
        return 1
    else
        # get vpc_id from sg
        sg_vpc_id=$(aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[0].VpcId' --output text 2>/dev/null)
        
        # rice an error if vpc_ids differ
        if [ "$subnet_vpc_id" != "$sg_vpc_id" ]; then
            echo "VPC IDs don't match"
            exit 1
        else
            # store the vpc_id
            vpc_id="$subnet_vpc_id"
            echo "VPC IDs match: $vpc_id"
        fi
    fi
fi
