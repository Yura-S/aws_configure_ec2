main script is create_ec2.sh

arguments

1) -c for creating
   -d for deleting (not working yet)

2) --ami
   enter ami-id

3) --vpc
   enter vpc-id or vpc name

4) --subnet
   enter subnet-id or pub or priv

5) --sg
   enter security group id or ports. ports must be in format
   
   port1:port2:port3:
   
   can add many ports 

only with aws vpcs where CIDR is 10.0.0.0/24



for cleanup_vpc_by_id.sh give argument - vpc id

for cleanup_vpcs_by_tag.sh give argument - tag 
