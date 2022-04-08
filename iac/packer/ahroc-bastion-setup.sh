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
