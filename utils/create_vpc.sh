#!/bin/bash
source create_sg.sh

mapPublicIpOnLaunch=true

# returns true if the subnet is private
get_MapPublicIpOnLaunch() {
    local subnet=$1

    if [ $subnet = "private" ]; then
        mapPublicIpOnLaunch=false
    fi
}

# creates a VPC with DNS IG and RT and return the created vpc id
create_vpc() {
	port=$1
	subnet=$2

    # create a VPC with 10.0.0.0/16 CIDR block
    vpc_id=$(aws ec2 create-vpc \
    	--cidr-block 10.0.0.0/16 \
    	--query 'Vpc.VpcId' \
    	--output text) \
    	&& echo "VPC created" || exit 1

	# check for blank id
	if [ -z "$vpc_id" ]; then
        echo "Invalid vpc id" && return 1  
    else
	# add a delete tag
        aws ec2 create-tags \
            --resources $vpc_id \
            --tags Key=to_be_deleted,Value=true

	echo "$vpc_id vpc created and tagged"
    fi

    # # enable DNS hostname of a VPC
    # aws ec2 modify-vpc-attribute \
    # 	--vpc-id $vpc_id \
    # 	--enable-dns-hostnames "{\"Value\":true}" \
    # 	&& echo "DNS hostname enabled"

    # create an Internet Gateway
    igw_id=$(aws ec2 create-internet-gateway \
    	--query 'InternetGateway.InternetGatewayId' \
    	--output text) \
    	&& echo "Internet Gateway created" || exit 1

	# check for blank id
	if [ -z "$igw_id" ]; then
        echo "Invalid igw id" && return 1  
    else
	# add a delete tag
        aws ec2 create-tags \
            --resources $igw_id \
            --tags Key=to_be_deleted,Value=true

		echo "$igw_id igw created and tagged"
    fi

    # attach the gateway to VPC
    aws ec2 attach-internet-gateway \
        --internet-gateway-id $igw_id \
        --vpc-id $vpc_id \
    	&& echo "attached the gateway to VPC" || exit 1
    
    # create a route table
    rt_id=$(aws ec2 create-route-table \
    	--vpc-id $vpc_id \
    	--query 'RouteTable.RouteTableId' \
    	--output text) \
    	&& echo "Route Table created" || exit 1

	# check for blank id
	if [ -z "$rt_id" ]; then
        echo "Invalid rt id" && return 1  
    else
	# add a delete tag
        aws ec2 create-tags \
            --resources $rt_id \
            --tags Key=to_be_deleted,Value=yes

		echo "$rt_id rt created and tagged"
    fi

    # add Route to Route Table
    aws ec2 create-route \
    	--route-table-id $rt_id \
    	--destination-cidr-block 0.0.0.0/0 \
    	--gateway-id $igw_id \
    	&& echo "added Route to Route Table" || exit 1

	# get if subnet is public or orivate
	get_MapPublicIpOnLaunch $subnet

	# create a subnet with an IPv4 CIDR block
    subnet_id=$(aws ec2 create-subnet \
        --vpc-id $vpc_id \
        --cidr-block 10.0.0.0/24 \
    	--availability-zone us-east-2a \
    	--query 'Subnet.SubnetId' \
		--map-public-ip-on-launch $mapPublicIpOnLaunch \
    	--output text) \
    	&& echo "subnet created" || exit 1

	# check for blank id
	if [ -z "$subnet_id" ]; then
        echo "Invalid subnet id" && return 1  
    else
	# add a delete tag
        aws ec2 create-tags \
            --resources $subnet_id \
            --tags Key=to_be_deleted,Value=yes

		echo "$subnet_id subnet created and tagged"
    fi
    
    # enable auto-assign public IPV4 addr of a subnet
    aws ec2 modify-subnet-attribute \
    	--subnet-id $subnet_id \
    	--map-public-ip-on-launch \
    	&& echo "enabled auto-assign public IPV4 addr of a subnet" || exit 1

    # associate a route table with a subnet
    aws ec2 associate-route-table \
    	--route-table-id $rt_id \
    	--subnet-id $subnet_id \
    	&& echo "associated a route table with a subnet" || exit 1

	# create security group
	create_sg $vpc_id $port
}
