######################
# Required Variables #
######################
db_username	= "test_admin"
db_password	= "Password1234!"

public_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy+u/d4TOYvxWmUMZ/Brx8M3IQa0xFKcCv6TiKTj1ZREWZHJScwWvubTdzKxm4Q/COLo2VYRt9/YRiqfhEmq3bguyHtlHrSEPQWOiQNhEU0qO/ZS2I7xY1wtV1GVUSdmhMhj+nsRt2RhTwQ5tqkSgQbsNo5p794yG4nwq4eZkfa5HfcHJ3J9ajq2es7nv8OIoKBfD4Z+sgiPoqDVL2AeFxfKGX3GqGpoQhZa+tMyyT8oLYXZd1T5pZLAoa5a7qla904GmKrXUM597z+9JzOPjiSpAsalVLTydBW2D7y5UX3tFyTI2T+LgV/gG+Ing0Xruo5NMFfS/3AdIyYfNQl7Qx Adam@Adam-MacBook.local"

keypair_name	= "test-keypair"
key_s3_bucket_name	= "test-bucket-random-34262352"

##################################################################
# If you want to change the initial number of nodes in your ASGs #
##################################################################
# Workers (Default: 3)
# k3s_agent_count = 3

# Servers (Default: 3)
# k3s_server_count = 3

#####################################################################
# If you want to define your own CIDR ranges for your VPCs/subnets! #
#####################################################################
# vpc_cidr = "10.0.0.0/16"
# private_subnet_1_cidr = "10.0.1.0/24"
# private_subnet_2_cidr = "10.0.2.0/24"
# public_subnet_1_cidr = "10.0.11.0/24"
# public_subnet_2_cidr = "10.0.12.0/24"

