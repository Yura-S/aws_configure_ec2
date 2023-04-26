#!/bin/bash

workdir=`pwd`
source $workdir/utils/validation.sh
source $workdir/utils/creation.sh

function validate_all() {
echo

	if [[ ${#vpc_id} -gt 1 ]]; then
	echo "gived vpc id"

		if [[ ${#subnet_id} -gt 1 ]]; then
		echo "gived subnet id"
      			
			if [[ ${#sg_id} -gt 1 ]]; then
        		echo "gived security group id"
        		VPC_ID1=$(aws ec2 describe-subnets --subnet-id $subnet_id --query Subnets[].VpcId --output text)
        		VPC_ID2=$(aws ec2 describe-security-groups --group-ids $sg_id --query SecurityGroups[].VpcId --output text)
        			
				if [[ $VPC_ID1 == $VPC_ID2 ]] && [[ $VPC_ID1 == $vpc_id ]]; then
          			echo "need to create only instance in $vpc_id"
        			else
          			echo "subnet and security group in different vpcs or in other vpc"
          			exit 1
        			fi
			
			elif [[ ${#sg_ports} -gt 1 ]]; then
        		echo "gived security port"
        		VPC_ID3=$(aws ec2 describe-subnets --subnet-id $subnet_id --query Subnets[].VpcId --output text)
        			
				if [[ $VPC_ID3 == $vpc_id ]]; then
          			echo "need to create security group in $vpc_id then need to create instance"
          			create_sg $sg_ports $vpc_id
				else
				echo "subnet in other vpc"
				exit 1
				fi
			
			fi

		elif [[ ${#subnet} -gt 1 ]]; then
		echo "gived subnet type pub/priv"
			
			if [[ ${#sg_id} -gt 1 ]]; then
			echo "gived security group id"
			VPC_ID4=$(aws ec2 describe-security-groups --group-ids $sg_id --query SecurityGroups[].VpcId --output text)
				
				if [[ $VPC_ID4 == $vpc_id ]]; then
          			echo "need to create $subnet subnet in $vpc_id then need to create instance"
				create_subnet $vpc_id $subnet
				else
				echo "security group in other vpc"
				exit 1
				fi
			
			elif [[ ${#sg_ports} -gt 1 ]]; then
			echo "needs to create security group and subnet and instance in $vpc_id then need to create instance"
			create_sg $sg_ports $vpc_id
			create_subnet $vpc_id $subnet
			
			else
			echo "invalid argument for sg"
			exit 1
			
			fi
		else
		echo "incorrect subnet"
		exit 1
		
		fi

	elif [[ ${#vpc_name} -gt 1 ]]; then
		
		if [[ ${#subnet_id} -gt 1 ]]; then
		echo "Error: Wrong argument for subnet id. Subnet should be priv/pub when vpc name provided"
		exit 1
		
		elif [[ ${#sg_id} -gt 1 ]]; then
		echo "Error: Wrong argument for sg. sg should be ports when vpc name provided"
		exit 1
		
		elif [[ ${#subnet} -gt 1 ]] && [[ ${#sg_ports} -gt 1 ]]; then	    
		echo "need to create vpc,subnet,security group,instance"
		create_vpc $vpc_name && echo "vpc created"
		create_sg $sg_ports $vpc_id && echo "sg created"
		create_subnet $vpc_id $subnet && echo "subnet created"
		
		else
		echo "wrong subnet or port arguments"
		exit 1      
		fi
	
	else
	echo "incorrect vpc"
fi

create_instance $ami_id $subnet_id $sg_id
}

# A string with command options
options=$@

# An array with all the arguments
arguments=($options)

sg_name="ec2SecurityGroup"
index=0

for i in "${!arguments[@]}"; do
  value_idx=$((++x))
  value=${arguments[value_idx]}
  #  printf "y = $y   %s\t%s\n" "$i" "${arguments[$i]}"
  case ${arguments[$i]} in
  -c)
    method="create"
    ;;
  -d)
    method="delete"
    ;;
  --ami)
    validate_ami_option $value
    ;;
  --vpc)
    validate_vpc_option $value
    ;;
  --subnet)
    validate_subnet_option $value
    ;;
  --sg)
    validate_sg_option $value
    ;;
  esac
done

if [[ $method == "create" ]]; then
validate_all

elif [[ $method == "delete" ]]; then
echo "removing all vpcs with to_be_deleted=true tag"
./cleanup_vpcs_by_tag.sh to_be_deleted

else
echo "Invalid option"

fi
