#!/bin/bash

# splits string to list by ":"
function split_string_to_list() {
  local IFS=':'    
  read -ra parts <<< "$1"    
  echo "${parts[@]}"    
}

# creates a segurity group with a given vpc id and ports
# ports are splitted by colons (:)
create_sg_instance() {
    local vpc_id=$1
    local port=$2

    # create security group
    sg_id=$(aws ec2 create-security-group \
    	--group-name Port22SecurityGroup \
    	--description "Port 22 security group" \
    	--vpc-id $vpc_id \
    	--query 'GroupId' \
    	--output text) \
    	&& echo "Port $port Security Group created" || exit 1
    
    # open ingress rules with a given port
    aws ec2 authorize-security-group-ingress \
    	--group-id $sg_id \
    	--protocol tcp \
    	--port $port \
    	--cidr 0.0.0.0/0 \
    	&& echo "opened ingress rules for the port $port" || exit 1
}

# get security groups
function create_sg() {
    local vpc_id=$1
    local ports=$2

	# split the ports
	local ports_list=$(split_string_to_list "$ports")
	echo "ports are splited $ports_list"

	# the list of security groups
	local security_group_ids=()

	# create sg for each port and store it into a list
	for port in $ports_list
	do
		local sg=$(create_sg_instance "$vpc_id" "$port")
		security_group_ids+=("$sg")
	done 

	# return sgs list
	echo "security groups are created ${security_group_ids[@]}"
}