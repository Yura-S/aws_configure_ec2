#!/bin/bash

source ./validation.sh


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

function valitade_all(){
  avi_zone=`aws ec2 describe-availability-zones --region $region | grep ZoneName | head -n 1 | awk -F\" '{print $4}'` &&

  if [[ -n $subnet_id ]]; then
    if [[ -n $vpc_id ]]; then

        ########################## Checking subnet in vpc #################################
        subnet_in_vpc=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id \
                        Name=subnet-id,Values=$subnet_id --output text)
        if [[ -z $subnet_in_vpc ]]; then
          echo "Error: Subnet not in vpc"
          exit 1
        fi
        ###################################################################################

        # 
        if [[ -n $sg_id ]]; then

          ############################## Check vpc is in sg ###############################
          sg_in_vpc=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc_id \
                      --query "SecurityGroups[].GroupId" | grep $sg_id)
          if [[ -z $sg_in_vpc ]]; then
            echo "Error: sg does not associated vpc but must be"
            exit 1
          fi
          #################################################################################

          ############################# Check subnet is in sg #############################
          sg_in_subnet=$(aws ec2 describe-subnets --filters Name=subnet-id,Values=subnet_id \
                      --query "Subnets[].Groups[].GroupId" | grep sg_id)
          if [[ -z sg_in_subnet ]]; then
            echo "Error: sg does not associated subnet but must be"
          fi
          #################################################################################

          echo "All values are valid!"
          echo "Done"

        else
          # question what to do when vpc_id and subnet_id exists but security group option provide only ports
          echo "Error: Security group id should be provided when vpc id and subnet exists"
        fi
    else
      echo "Error: Vpc should be provided when subnet id exists"
    fi
  else
    ### todo check when subnet is not id ### Sea Gevorgs comment ### elif subnet argument is priv/pub ###
    echo subnet is $subnet
    
    # if vpc id is null then crate vpc id
    if [[ -z vpc_id ]]; then
      vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query Vpc.VpcId --output text)
      create_subnet $subnet $vpc_id $avi_zone
    fi
  fi
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
  echo chreating vpc

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