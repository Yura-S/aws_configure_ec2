#!/bin/bash

function validate_vpc_option()
{
if [[ $1 =~ ^[-][-]* ]]; then
echo empty vpc
exit 1

elif [[ $1 =~ ^vpc-[a-f0-9]{16,17} ]]; then
VPC_COUNT=`aws ec2 describe-vpcs --vpc-id $1 --query Vpcs[].VpcId --output text | wc -l`
	if [[ $VPC_COUNT -ne 1  ]]; then
	echo "not found vpc"
	exit 1
	else     
	vpc_id=$1	      
	fi

else
	vpc_name=$1
fi
}

function validate_subnet_option()
{
if [[ $1 =~ ^[-][-]* ]]; then
echo empty subnet	
exit 1  

elif [[ $1 = "priv" ]]; then
subnet=$1

elif [[ $1 = "pub" ]]; then
subnet=$1

elif [[ $1 =~ ^subnet-[a-f0-9]{16,17} ]]; then
subnet_id=$1
result=`aws ec2 describe-subnets | grep $subnet_id`  

	if [[ -z $result ]]; then
	echo "Invalid subnet id $subnet_id: please input valid subnet option"
	exit 1
	fi

else
echo "Invalid subnet: subnet should be priv | pub | or existing subnet-id"
exit 1
fi
}

function validate_sg_option()
{
sg_id=""
if [[ -z $1  ]]; then
echo security group is empty
exit 1     

elif [[ $1 =~ ^sg-[a-f0-9]{16,17} ]]; then
SG_COUNT=`aws ec2 describe-security-groups --group-ids $1 --query SecurityGroups[].GroupId --output text | wc -l`
	if [[ $SG_COUNT -ne 1 ]]; then
	echo "not found sg"
	exit 1
	else   
	sg_id=$1
	fi

elif [[ $1 =~ ^(((6553[0-5][:])|(655[0-2][0-9][:])|(65[0-4][0-9]{2}[:])|(6[0-4][0-9]{3}[:])|([1-5][0-9]{4}[:])|([1-9][0-9]{0,3}[:])){1,})$ ]]; then
sg_ports=`echo "$1" | tr "-" " "` # "10-20-330" -> "10 20 330"

else
echo Invalid sg option
exit 1

fi
}

function validate_ami_option()
{	
if [[ $1 =~ ^[-][-]* ]]; then
echo empty ami
exit 1

elif [[ $1 =~ ^ami-[a-f0-9]{16,17} ]]; then
AMI_COUNT=`aws ec2 describe-images --image-ids $1 --query Images[].ImageId --output text | wc -l`
	if [[ $AMI_COUNT -ne 1 ]]; then
	echo "not found ami"
	exit 1
	else
	ami_id=$1	    
	fi

else
echo invalid ami id
exit 1

fi   
}
