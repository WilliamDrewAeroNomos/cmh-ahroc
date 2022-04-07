
# Service linked role

#resource "aws_iam_service_linked_role" "es" {
#  aws_service_name = "es.amazonaws.com"
#}

# Creating the Elasticsearch domain

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type = var.instance_type
  }
  snapshot_options {
    automated_snapshot_start_hour = 23
  }
  vpc_options {
    subnet_ids = [data.terraform_remote_state.network.outputs.public_subnet_ids[1]]   
  }
  
  ebs_options {
    ebs_enabled = var.ebs_volume_size > 0 ? true : false
    volume_size = var.ebs_volume_size
    volume_type = var.volume_type
  }
  tags = {
    Domain = var.tag_domain
  }
}

# Creating the AWS Elasticsearch domain policy

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name     = aws_elasticsearch_domain.es.domain_name
  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "${aws_elasticsearch_domain.es.arn}/*"
        }
    ]
}
POLICIES
}


