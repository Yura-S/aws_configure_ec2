#!/bin/bash

#-------------------------------------check vpc
if [ -z $1  ]; then
        echo NOT GIVED VPC ID
        exit 1
fi

ALL_VPCS_COUNT=(`aws ec2 describe-vpcs --query Vpcs[].[VpcId] --output text | wc -l`)
ALL_VPCS=(`aws ec2 describe-vpcs --query Vpcs[].[VpcId] --output text`)
for (( i=0; i<$ALL_VPCS_COUNT; i++ ))
do
if [ "${ALL_VPCS[$i]}" = "$1" ]; then
        break
elif [ $i -eq $((ALL_VPCS_COUNT - 1)) ]; then
        echo VPC ID IS INCORRECT
        exit 1
fi
done

#--------------------------------------delete instances

INSTANCES_COUNT=`aws ec2 describe-instances --filters Name=vpc-id,Values=$1 --query 'Reservations[].Instances[].[InstanceId]' --output text | wc -l`
INSTANCES=(`aws ec2 describe-instances --filters Name=vpc-id,Values=$1 --query 'Reservations[].Instances[].[InstanceId]' --output text`)
echo INSTANCES COUNT IS $INSTANCES_COUNT
for (( i=0; i<$INSTANCES_COUNT; i++ ))
do
aws ec2 terminate-instances --instance-ids ${INSTANCES[$i]}
echo DELETING INSTANCE ${INSTANCES[$i]}
done

#--------------------------------------sleep for terminate

echo SLEEPING TWO MINUTES WHILE INSTANCES TERMINATING
sleep 120

#--------------------------------------delete security groups
SECURITY_GROUPS_COUNT=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$1 --query 'SecurityGroups[].[GroupId]' --output text | wc -l`
SECURITY_GROUPS=(`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$1 --query 'SecurityGroups[].[GroupId]' --output text`)
echo SECURITY GROPEP COUNT IS $SECURITY_GROUPS_COUNT
for (( i=0; i<$SECURITY_GROUPS_COUNT; i++ ))
do
aws ec2 delete-security-group --group-id ${SECURITY_GROUPS[$i]}
echo DELETING SECURITY GROUP ${SECURITY_GROUPS[$i]}
done
sleep 3

#--------------------------------------delete subnets

SUBNET_COUNT=`aws ec2 describe-subnets --filters Name=vpc-id,Values=$1 --query 'Subnets[].[SubnetId]' --output text | wc -l`
SUBNETS=(`aws ec2 describe-subnets --filters Name=vpc-id,Values=$1 --query 'Subnets[].[SubnetId]' --output text`)
echo SUBNETS COUNT IS $SUBNET_COUNT

for (( i=0; i<$SUBNET_COUNT; i++ ))
do
aws ec2 delete-subnet --subnet-id ${SUBNETS[$i]}
echo DELETING SUBNET ${SUBNETS[$i]}
done
sleep 3

#--------------------------------------delete route tables

ROUTE_TABLES_COUNT=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$1 --query 'RouteTables[].[RouteTableId]' --output text | wc -l`
ROUTE_TABLES=(`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$1 --query 'RouteTables[].[RouteTableId]' --output text`)
echo ROUTE TABLES COUNT IS $ROUTE_TABLES_COUNT

for (( i=0; i<$ROUTE_TABLES_COUNT; i++ ))
do
aws ec2 delete-route-table --route-table-id ${ROUTE_TABLES[$i]}
echo DELETING ROUTE TABLE ${ROUTE_TABLES[$i]}
done
sleep 3

#--------------------------------------get internet gateway id

INTERNET_GATEWAY_ID=`aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$1 --query InternetGateways[].InternetGatewayId --output text`
echo INTERNET GATEWAY ID IS $INTERNET_GATEWAY_ID

#--------------------------------------detach internet gateway

aws ec2 detach-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $1
echo INTERNET GATEWAY $INTERNET_GATEWAY_ID DETACHED FROM VPC $1
sleep 3

#--------------------------------------delete internet gateway

aws ec2 delete-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID
echo INTERNET GATEWAY $INTERNET_GATEWAY_ID DELETED
sleep 3

#--------------------------------------delete vpc

aws ec2 delete-vpc --vpc-id $1
echo VPC $1 DELETED

