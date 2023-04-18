#!/bin/bash

# source create_subnet.sh
# source create_sg.sh

#!/bin/bash

subnet_id=$1
sg_id=$2

if [ -z "$subnet_id" ]; then
    echo "Invalid argument is provided."
    exit 1
else
    ## create_subnet.sh - ստեղ կանչում ենք սկրիպտը համապատասխան, հետո տակինով վերցնում ու պահում vpc_id-ն subnet_vpc_id-ի մեջ
    subnet_vpc_id=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].VpcId' --output text 2>/dev/null)

    if [ -z "$sg_id" ]; then
        echo "Invalid argument is provided"
        exit 1
    else
        ## create_sg.sh - ստեղ կանչում ենք սկրիպտը համապատասխան, հետո տակինով վերցնում ու պահում vpc_id-ն sg_vpc_id-ի մեջ
        sg_vpc_id=$(aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[0].VpcId' --output text 2>/dev/null)
        
        if [ "$subnet_vpc_id" != "$sg_vpc_id" ]; then
            echo "VPC IDs don't match"
            exit 1
        else
            matching_vpc_id="$subnet_vpc_id"
            echo "VPC IDs match: $matching_vpc_id"
        fi
    fi
fi
