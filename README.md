main script is create_ec2.sh

arguments

1) -c for creating
   -d for deleting (deletes all vpcs which have to_be_deleted tag and his components have to_be_deleted tag)

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



for cleanup_vpc_by_id.sh give argument - vpc id

for cleanup_vpcs_by_tag.sh give argument - tag 
