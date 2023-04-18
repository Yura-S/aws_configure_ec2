#!/bin/bash
aws_region="us-east-1"
vpc_cidr="to_be_discussed" # CIDR-ը կավելացնենք հետո
subnet_public_cidr="to_be_discussed" # CIDR-ը կավելացնենք հետո
subnet_public_az="us-east-1a"
subnet_private_cidr="to_be_discussed" # CIDR-ը կավելացնենք հետո
subnet_private_az="us-east-1b"

### Create VPC ###
echo "Creating VPC in a certain region"
vpc_id=$(aws ec2 create-vpc \
    --cidr-block $vpc_cidr \
    --query 'Vpc.{VpcId.VpcId}' \
    --output text \
    --region $aws_region)
echo "VPC $vpc_id is created in $aws_region region."

## Adding a tag to VPC (to_be_deleted) for further usage during cleanup
aws ec2 create-tags \
    --resources $vpc_id
    --tags "key=to_be_deleted, value=true" \
    --region $aws_region
echo "Tag is added to VPC $vpc_id"

echo "Creating a Public Subnet"
subnet_public_id=$(aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block $subnet_public_cidr \
    --availability-zone $subnet_public_az \
    --query 'Subnet.{SubnetId:SubnetId}' \
    --output text \
    --region $aws_region)
echo "Public Subnet $subnet_public_id is created in $subnet_public_az"

## Adding a tag to PUBLIC subnet for further usage during cleanup
aws ec2 create-tags \
    --resources $subnet_public_id
    --tags "key=to_be_deleted, value=true" \
    --region $aws_region
echo "Tag is added to Public Subnet $subnet_public_id"

echo "Creating a Private Subnet"
subnet_private_id=$(aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block $subnet_private_cidr \
    --availability-zone $subnet_private_az \
    --query 'Subnet.{SubnetId:SubnetId}' \
    --output text \
    --region $aws_region)
echo "Private Subnet $subnet_private_id is created in $subnet_private_az"

## Adding a tag to PRIVATE subnet for further usage during cleanup
aws ec2 create-tags \
    --resources $subnet_private_id
    --tags "key=to_be_deleted, value=true" \
    --region $aws_region
echo "Tag is added to Private Subnet $subnet_private_id"

## Creating Internet Gateway
igw_id=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
    --output text \
    --region $aws_region)
echo "Internet Gateway ID $igw_id is created"
