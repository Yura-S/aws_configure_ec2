function validate_vpc_option(){
  if [[ $1 =~ ^vpc-[a-f0-9]{16,17} ]]; then
      vpc_id=$1
      echo vpc id is valid
  else
    if [[ -z $1 ]]; then
      echo "empty vpc argumet"
      exit 1
    else
      vpc_name=$1
      echo vpc name: $vpc_name
    fi
  fi
}


function validate_subnet_option(){
  if [[ $1 = "priv" ]]; then
    echo subnet is private
    subnet=$1
  elif [[ $1 = "pub" ]]; then
    echo subnet is public
    subnet=$1

  elif [[ $1 =~ ^subnet-[a-f0-9]{16,17} ]]; then
    subnet_id=$1
    result=`aws ec2 describe-subnets | grep $subnet_id`
    
    if [[ -z $result ]]
    then
      echo "Invalid subnet id $subnet_id: please input valid subnet option"
      exit 1
    else
      echo "Subnet id is valid"
    fi

  else
    echo "Invalid subnet: subnet should be priv | pub | or existing subnet-id"
    exit 1
  fi
}


function validate_sg_option(){
  if [[ ^sg-[a-f0-9]{16,17} ]]; then
    sg_id=$1
    is_exists=$(aws ec2 describe-security-groups --group-ids $sg_id | grep GroupId)
    if [[ -z is_exists ]]; then
      echo "Error: The security group '$sg_id' does not exist"
      exit 1
    else
      echo "Security group id is valid"
    fi
  elif [[ $1 =~ ^([0-9]{1,5}:){2,4}$ ]]; then
    echo security group ports exist
    sg_ports=`echo "$1" | tr ":" " "` # "10:20:330" -> "10 20 330"
  else
    echo Invalid sg option
    exit 1
  fi
}