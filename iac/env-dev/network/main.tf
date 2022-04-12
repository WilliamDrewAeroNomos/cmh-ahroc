#---------------------------
# Development environment
#---------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "nat_instance_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_accessanalyzer_analyzer" "access_analyzer" {
  analyzer_name = "AHROC"
}

#---------------------------
# VPC
#---------------------------

resource "aws_vpc" "main" {
  cidr_block           = "${var.CIDR_BLOCK}"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags = {
    Name = "${var.VPC_NAME}"
  }
}

# Public Subnets

resource "aws_subnet" "public_subnets" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.ENVIRONMENT}_public_subnet_${data.aws_availability_zones.available.names[count.index]}"
  }
}

# Private Subnets

resource "aws_subnet" "private_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index + 3]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 4)

  tags = {
    Name = "${var.ENVIRONMENT}_private_subnet_${data.aws_availability_zones.available.names[count.index]}"
    Type = "Private"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.ENVIRONMENT}-igw"
  }
}

# Public route table

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.ENVIRONMENT}-public_route_table"
  }
}

# Public route

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_main.id
}

# Public route table associations - public subnets to public route table

resource "aws_route_table_association" "public_route_table_association" {
  count          = 3
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

# Associating private route table with private subnets

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.VPC_NAME}_Private_Route_Table"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 3
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

# NAT'd subnets

resource "aws_subnet" "nated_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 8)
  availability_zone = data.aws_availability_zones.available.names[count.index + length(aws_subnet.public_subnets)]

  tags = {
    Name = "${var.ENVIRONMENT}-nated-subnet-${data.aws_availability_zones.available.names[count.index + length(aws_subnet.public_subnets)]}"
  }
}

# EIPs

resource "aws_eip" "nat_gw_eips" {
  count = 3
  vpc   = true
}

# NAT gateway

resource "aws_nat_gateway" "nat_gateways" {
  count         = 3
  allocation_id = element(aws_eip.nat_gw_eips.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)
}

# NAT'd subnet route tables

resource "aws_route_table" "nated_route_tables" {
  count  = 3
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateways.*.id, count.index)
  }

  tags = {
    Name = "${var.ENVIRONMENT}-nated-rt-${count.index + 1}"
  }
}

# Associations for NAT'd subnets and route tables

resource "aws_route_table_association" "nated_route_table_associations" {
  count          = 3
  subnet_id      = element(aws_subnet.nated_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.nated_route_tables.*.id, count.index)
}

# NAT'd security group

resource "aws_security_group" "nat_sg" {
  name   = "nat_instance_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_subnets.*.cidr_block
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_subnets.*.cidr_block
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = aws_subnet.private_subnets.*.cidr_block
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NAT_Instance_Security_Group"
  }
}



