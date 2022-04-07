#
#
#

# ------------------------------------------
# AMI created via Packer and retrieved via data API
# ------------------------------------------

data "aws_ami" "nodejs-image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "tag:component-name"
    values = ["ahroc-nodejs-image"]
  }
}

# ------------------------------------------
# Access key to front-end EC2 instances
# ------------------------------------------

resource "aws_key_pair" "ahroc-front-end-key" {
  key_name   = "ahroc-front-end-key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}

# ------------------------------------------
# Front-end security group
# ------------------------------------------

resource "aws_security_group" "ahroc-front-end-sg" {
  vpc_id      = data.terraform_remote_state.network.outputs.vpc-main-id
  name        = "ahroc-front-end-sg"
  description = "Security group for AHROC front-end instances"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.ahroc-front-end-elb-sg.id]
  }

  tags = {
    Name = "ahroc-front-end-elb-sg"
  }
}

# ------------------------------------------
# Elastic load balancer security group
# ------------------------------------------

resource "aws_security_group" "ahroc-front-end-elb-sg" {
  vpc_id      = data.terraform_remote_state.network.outputs.vpc-main-id
  name        = "ahroc-front-end-elb-sg"
  description = "Security group for the AHROC front end ELB"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ahroc-front-end-elb-sg"
  }
}

# ------------------------------------------
# Elastic load balancer
# ------------------------------------------

resource "aws_elb" "ahroc-front-end-elb" {
  name = "ahroc-front-end-elb"

  subnets = [element(data.terraform_remote_state.network.outputs.public_subnet_ids, 0),
    element(data.terraform_remote_state.network.outputs.public_subnet_ids, 1),
  element(data.terraform_remote_state.network.outputs.public_subnet_ids, 2)]

  security_groups = [aws_security_group.ahroc-front-end-elb-sg.id]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/healthz"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "ahroc_front_end_sg_elb"
  }
}

# ------------------------------------------
# Launch configuration
# ------------------------------------------

resource "aws_launch_configuration" "ahroc-front-end-launch-configuration" {
  name_prefix     = "ahroc-front-end-launch-configuration"
  image_id        = data.aws_ami.nodejs-image.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.ahroc-front-end-key.key_name
  security_groups = [aws_security_group.ahroc-front-end-sg.id]
}

# ------------------------------------------
# Auto-scaling group
# ------------------------------------------

resource "aws_autoscaling_group" "ahroc-front-end-autoscaling" {
  name = "ahroc-front-end-autoscaling"
  vpc_zone_identifier = [element(data.terraform_remote_state.network.outputs.public_subnet_ids, 0),
    element(data.terraform_remote_state.network.outputs.public_subnet_ids, 1),
  element(data.terraform_remote_state.network.outputs.public_subnet_ids, 2)]
  launch_configuration      = aws_launch_configuration.ahroc-front-end-launch-configuration.name
  min_size                  = 10
  max_size                  = 50
  health_check_grace_period = 300
  health_check_type         = "EC2"
  load_balancers            = [aws_elb.ahroc-front-end-elb.name]
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "AHROC front end"
    propagate_at_launch = true
  }
}