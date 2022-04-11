
# Network

CIDR_BLOCK  = "10.0.0.0/16"
VPC_NAME    = "development"
ENVIRONMENT = "development"

# Persistence

domain          = "ahroc-development"
instance_type   = "r4.large.elasticsearch"
tag_domain      = "AHROC-Domain"
volume_type     = "gp2"
ebs_volume_size = 10

# MongoDB

vpc_name            = "mongo_vpc"
replica_set_name    = "mongoRs"
num_secondary_nodes = 2
mongo_username      = "admin"
mongo_password      = "mongo4pass"
mongo_database      = "admin"
primary_node_type   = "t2.micro"
secondary_node_type = "t2.micro"

key_name = "mongo-key-pair"