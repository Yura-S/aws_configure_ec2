#!/bin/bash

function create_sg()
{
echo "creating security group"
sg_ports=`echo "$1" | tr ":" " "` # "10:20:330" -> "10 20 330"
sg_name=`echo $RANDOM | md5sum | head -c 10`
 
sg_id=$(aws ec2 create-security-group \
     --group-name $sg_name \
     --description "my security group" \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=to_be_deleted,Value=true}]' \
     --vpc-id $2 \
     --query 'GroupId' \
     --output text)

if [ -z "$sg_id" ]; then
echo "Security group does not exists"
exit 1
fi

for port in $sg_ports
do
	aws ec2 authorize-security-group-ingress \
		--group-id $sg_id \
		--protocol tcp \
		--port $port \
		--cidr 0.0.0.0/0 \
		--output text >> /dev/null
	echo "Allow $port for $sg_id"
done
}

function create_instance()
{
echo "creating instance"
instance_id=`aws ec2 run-instances \
	--image-id $1 \
	--count 1 \
	--instance-type t2.micro \
	--security-group-ids $3 \
	--block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=new_instance},{Key=to_be_deleted,Value=true}]' \
	--subnet-id $2 \
	--region us-east-1 \
	--query Instances[0].InstanceId \
	--output text`
echo "created instance $instance_id"
}

function create_subnet()
{
echo "starting search available ip range to create subnet please wait"
subnet_id=""
ip_network_part=$(aws ec2 describe-vpcs --vpc-id $1 --query Vpcs[].CidrBlock --output text | sed 's/\/[^/]*$//' | sed 's/\.[^.]*$//' | sed 's/\.[^.]*$//')

for i in {0..255}
do
	temp_cidr="$ip_network_part.$i.0/24";
	aws ec2 create-subnet --vpc-id $1 --tag-specifications 'ResourceType=subnet,Tags=[{Key=to_be_deleted,Value=true}]' --cidr-block $temp_cidr > /dev/null 2>&1
	created_status=$?
	
	if [[ $created_status == 0 ]]; then
	echo "created private subnet with $temp_cidr cidr block"
	sleep 3

		if [[ $2 == "pub"  ]]; then
		subnet_id=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock=='$temp_cidr'].SubnetId" --output text)
		aws ec2 modify-subnet-attribute --subnet-id $subnet_id --map-public-ip-on-launch
		echo "changed to public"
		elif [[ $2 == "priv" ]]; then
		subnet_id=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock=='$temp_cidr'].SubnetId" --output text)	
		fi
		
	break
	
	elif [[ $created_status != 0 ]]; then
	echo "$temp_cidr not available"
		
		if [[ $i -eq 255 ]]; then
		echo "not found available ip rage"
		exit 1
		fi	
	
	fi
done
}

function create_vpc() 
{
vpc_name=$1
vpc_id=$(aws ec2 create-vpc \
	--cidr-block 10.0.0.0/16 \
	--tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$vpc_name},{Key=to_be_deleted,Value=true}]" \
	--query Vpc.VpcId --output text)
internet_gateway_id=`aws ec2 create-internet-gateway --region us-east-1 --query InternetGateway.InternetGatewayId --output text`
sleep 3

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $internet_gateway_id --region us-east-1
sleep 3

route_table_id=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc_id --query RouteTables[].RouteTableId --output text`
sleep 3

aws ec2 create-route --route-table-id $route_table_id --destination-cidr 0.0.0.0/0 --gateway-id $internet_gateway_id --region us-east-1 > /dev/null 2>&1
sleep 3
}
