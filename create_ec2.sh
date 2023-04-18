#!/bin/bash

source ./utils/validation.sh


create_sg()
{  
  # $1: argument of ports
 sg_ports=`echo "$1" | tr ":" " "` # "10:20:330" -> "10 20 330"

 sg_id=$(aws ec2 create-security-group \
     --group-name acatest \
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
            --group-id $SG_ID \
            --protocol tcp \
            --port $port \
            --cidr 0.0.0.0/8 \
            --output text >> /dev/null
    echo "Allow $port for $sg_id"
  done
}

function create_subnet(){
  # $1 -> priv or pub
  # $2 -> vpc_id
  # $3 -> availability-zone 
  if [[ $1 == "priv" ]]; then
    subnet_id=$(aws ec2 create-subnet \
        --vpc-id $$2 \
        --cidr-block 10.0.0.0/24 \
        --availability-zone $3 \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=delete,Value=true}]' \
        --subnet-type private \
        --map-public-ip-on-launch false)
  else
    subnet_id=$(aws ec2 create-subnet \
      --vpc-id $2 \
      --cidr-block 10.0.0.0/24 \
      --availability-zone $3 \
      --tag-specifications 'ResourceType=subnet,Tags=[{Key=delete,Value=true}]')

  fi
}

function validate_all(){
	echo	
	echo gived vpc id $vpc_id
	echo gived vpc name $vpc_name
	echo gived subnet type $subnet
	echo gived subnet id $subnet_id
	echo gived security group id $sg_id
	echo gived security group ports $sg_ports
        echo gived  ami id $ami_id

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


if [[ $method = "create" ]]; then
  validate_all

elif [[ $method = "delete" ]]; then
  echo removing vpc
  # todo write remove part
else
  echo "Invalid option"
fi


# check subnet argument:
#   if subnet argument is ID
#     check sg argument:
#       if sg argument is ID
#          compare vpc ID of subnet and sg:
#            if vpc id is the same, then vpcid
#            else error
#       elif sg argument is port
#          then get vpcid from subnet & create sg in vpcid
#       else error
#    elif subnet argument is priv/pub
#      check sg argument
#        if sg argument is id
#          get vpcid from sg & create subnet in vpcid
#      elif sg argument is port
#        create vpc & subnet & sg
#      else error
#   else error
# ./vpc.sh --vpc vpc-07c9dc6c837c38285 --subnet subnet-0b0e7a239425dce53 --sg sg-01df59770201c88df
