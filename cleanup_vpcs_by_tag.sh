#!/bin/bash

#------------------------------get vpcs where gived tag is true
echo
ALL_VPCS_COUNT=(`aws ec2 describe-vpcs --filters "Name=tag:$1,Values=true" --query Vpcs[].[VpcId] --output text | wc -l`)
echo "NUMBER OF FINDED VPCS WITH THAT TAG AND ITS IS TRUE $ALL_VPCS_COUNT"
echo

if [ $ALL_VPCS_COUNT -eq 0  ]; then
	echo NOT FOUND VPCS...STOPPING SCRIPT
        exit 0
fi

ALL_VPCS=(`aws ec2 describe-vpcs --filters "Name=tag:$1,Values=true" --query Vpcs[].[VpcId] --output text`)

#------------------------------starting delete vpcs by cycle

for (( i=0; i<$ALL_VPCS_COUNT; i++ ))
do
echo STARTING CHECK ${ALL_VPCS[$i]}

#------------------------------check for instances tags

ALL_INSTANCES_COUNT=`aws ec2 describe-instances --filters Name=vpc-id,Values=${ALL_VPCS[$i]} --query 'Reservations[].Instances[].[InstanceId]' --output text | wc -l`
INSTANCES_COUNT_WITH_TAG=`aws ec2 describe-instances --filters Name=vpc-id,Values=${ALL_VPCS[$i]} Name=tag:$1,Values=true --query 'Reservations[].Instances[].[InstanceId]' --output text | wc -l`
echo "${ALL_VPCS[$i]} HAVE $ALL_INSTANCES_COUNT INSTANCE(S)"
echo "${ALL_VPCS[$i]} HAVE $INSTANCES_COUNT_WITH_TAG INSTANCE(S) WITH TAG"

if [ $ALL_INSTANCES_COUNT -ne $INSTANCES_COUNT_WITH_TAG ]; then
	echo ${ALL_VPCS[$i]} HAVE INSTANCE WITHOUT TAG OR TAG IS FALSE. CANT DELETE VPC
	echo
	continue
fi

#------------------------------check for security groups tags
ALL_SG_COUNT=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=${ALL_VPCS[$i]} --query "SecurityGroups[?GroupName!='default'].[GroupId]"  --output text | wc -l`
SG_COUNT_WITH_TAG=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=${ALL_VPCS[$i]} Name=tag:$1,Values=true --query "SecurityGroups[?GroupName!='default'].[GroupId]" --output text | wc -l`
echo "${ALL_VPCS[$i]} HAVE $ALL_SG_COUNT NOT DEFAULT SECURITY_GROUP(S)"
echo "${ALL_VPCS[$i]} HAVE $SG_COUNT_WITH_TAG NOT DEFAULT SECURITY_GROUP(S) WITH TAG"

if [ $ALL_SG_COUNT -ne $SG_COUNT_WITH_TAG ]; then
        echo ${ALL_VPCS[$i]} HAVE SECURITY GROUP WITHOUT TAG OR TAG IS FALSE. CANT DELETE VPC
	echo
	continue
fi

#------------------------------check for subnets tags

ALL_SUBNETS_COUNT=`aws ec2 describe-subnets --filters Name=vpc-id,Values=${ALL_VPCS[$i]} --query "Subnets[].[SubnetId]" --output text | wc -l`
SUBNET_COUNT_WITH_TAG=`aws ec2 describe-subnets --filters Name=vpc-id,Values=${ALL_VPCS[$i]} Name=tag:$1,Values=true --query "Subnets[].[SubnetId]" --output text | wc -l`
echo "${ALL_VPCS[$i]} HAVE $ALL_SUBNETS_COUNT SUBNETS"
echo "${ALL_VPCS[$i]} HAVE $SUBNET_COUNT_WITH_TAG SUBNETS WITH TAG"


if [ $ALL_SUBNETS_COUNT -ne $SUBNET_COUNT_WITH_TAG ]; then
	echo ${ALL_VPCS[$i]} HAVE SUBNET WITHOUT TAG OR TAG IS FALSE. CANT DELETE VPC
	echo
	continue
fi

#------------------------------check for route table tags

ALL_RT_COUNT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=${ALL_VPCS[$i]} --query 'RouteTables[?Associations[0].Main != `true`].[RouteTableId]' --output text | wc -l)
RT_COUNT_WITH_TAG=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=${ALL_VPCS[$i]} Name=tag:$1,Values=true --query 'RouteTables[?Associations[0].Main != `true`].[RouteTableId]' --output text | wc -l)
echo ${ALL_VPCS[$i]} HAVE $ALL_RT_COUNT NOT DEFAULT ROUTE TABLES
echo ${ALL_VPCS[$i]} HAVE $RT_COUNT_WITH_TAG NOT DEFAULT ROUTE TABLES WITH TAG

if [ $ALL_RT_COUNT -ne $RT_COUNT_WITH_TAG ]; then
        echo ${ALL_VPCS[$i]} HAVE ROUTE TABLE WITHOUT TAG OR TAG IS FALSE. CANT DELETE VPC
        echo
        continue
fi

#------------------------------CHECK INTERNET GATEWAY
ALL_IGWS=`aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${ALL_VPCS[$i]} --query InternetGateways[].[InternetGatewayId] --output text | wc -l`
IGW_COUNT_WITH_TAG=`aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${ALL_VPCS[$i]} Name=tag:$1,Values=true --query InternetGateways[].[InternetGatewayId] --output text | wc -l`
echo ${ALL_VPCS[$i]} HAVE $ALL_IGWS INTERNET GATEWAYS
echo ${ALL_VPCS[$i]} HAVE $IGW_COUNT_WITH_TAG INTERNET GATEWAYS WITH TAG

if [ $ALL_IGWS -ne $IGW_COUNT_WITH_TAG ]; then
        echo ${ALL_VPCS[$i]} HAVE INTERNET GATEWAY WITHOUT TAG OR TAG IS FALSE. CANT DELETE VPC
        echo
        continue
fi

#------------------------------if checks passed show that vpc can be deleted

echo ${ALL_VPCS[$i]} CAN BE DELETED. STARTING IN BACKGROUND
./utils/cleanup_vpc_by_id.sh ${ALL_VPCS[$i]} &

echo
done

#------------------------------end of cycle
#------------------------------starting delete all pair keys with tag

KEY_PAIRS_WITH_TAG=(`aws ec2 describe-key-pairs --filter Name=tag:$1,Values=true --query KeyPairs[].[KeyPairId] --output text`)
KEY_PAIRS_WITH_TAG_COUNT=`aws ec2 describe-key-pairs --filter Name=tag:$1,Values=true --query KeyPairs[].[KeyPairId] --output text | wc -l`

for (( i=0; i<$KEY_PAIRS_WITH_TAG_COUNT; i++ ))
do
echo DELETING KEY ${KEY_PAIRS_WITH_TAG[$i]}
aws ec2 delete-key-pair --key-pair-id ${KEY_PAIRS_WITH_TAG[$i]}
done

