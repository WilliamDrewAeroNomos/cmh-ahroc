#!/bin/bash
echo "Configuring bastion host"

echo "Update the image to the latest patches"

sudo yum install epel-release -y
sudo yum update -y

echo "Install git..."

sudo yum install git -y

echo "Install yum-config-manager to manage your repositories..."

sudo yum install -y yum-utils

echo "Use yum-config-manager to add the official HashiCorp Linux repository..."

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

echo "Install Terraform..."

sudo yum -y install terraform

echo "Install Packer..."

sudo yum -y install packer

#echo "Clone down code repository..."

# git clone https://git-codecommit.us-gov-west-1.amazonaws.com/v1/repos/cmh-ahroc

echo "Install AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

echo "Add aliases for Terraform commands..."

echo "alias tf='terraform'" >> ~/.bash_profile
echo "alias tf_apply='tf apply -var-file=terraform.tfvars'" >> ~/.bash_profile
echo "alias tf_destroy='tf destroy -var-file=terraform.tfvars'" >> ~/.bash_profile
echo "alias tf_plan='tf plan -var-file=terraform.tfvars'" >> ~/.bash_profile