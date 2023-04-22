#!/bin/bash

function create_sg()
{
  # $1: argument of ports
  echo "creating security group"
 sg_ports=`echo "$1" | tr ":" " "` # "10:20:330" -> "10 20 330"

 sg_id=$(aws ec2 create-security-group \
     --group-name new_sg \
     --description "my security group" \
     --vpc-id $vpc_id \
     --query 'GroupId' \
     --output text)

  # todo check this part 
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
            --cidr 0.0.0.0/8 \
            --output text >> /dev/null
    echo "Allow $port for $sg_id"
  done
}

function create_instance(){
  # $1 -> ami
  # $2 -> subnet
  # $3 -> security group
  echo "creating instance"
  instance_id=`aws ec2 run-instances \
          --image-id $1 \
          --count 1 \
          --instance-type t2.micro \
          --security-group-ids $3 \
          --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' \
          --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=new_instance}]' \
          --subnet-id $2 \
          --region us-east-1 \
          --query Instances[0].InstanceId \
          --output text`
  echo "created instance $instance_id"
}

function create_subnet(){
  echo "starting search available ip range to create subnet please wait"
  ip_network_part=$(aws ec2 describe-vpcs --vpc-id $1 --query Vpcs[].CidrBlock --output text | sed 's/\/[^/]*$//' | sed 's/\.[^.]*$//' | sed 's/\.[^.]*$//')
  for i in {0..255}
  do
        temp_cidr="$ip_network_part.$i.0/24";
        aws ec2 create-subnet --vpc-id $1 --cidr-block $temp_cidr > /dev/null 2>&1
        created_status=$?
        if [[ $created_status == 0 ]]; then
        echo "created private subnet with $temp_cidr cidr block"
                if [[ $2 == "pub"  ]]; then
		sleep 3
                subnet_id=$(aws ec2 describe-subnets --query "Subnets[?CidrBlock=='$temp_cidr'].SubnetId" --output text)
                aws ec2 modify-subnet-attribute --subnet-id $subnet_id --map-public-ip-on-launch
                echo "changed to public"
                fi
        break
        elif [[ $created_status != 0 ]]; then
        echo "$temp_cidr not available"
        fi
  done
}
