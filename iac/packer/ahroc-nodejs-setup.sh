#!/bin/bash
echo "Executing base image setup"

echo "Update the image to the latest patches"

sudo yum update -y

sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

cat /etc/system-release

sudo yum install -y httpd

sudo systemctl start httpd

sudo systemctl enable httpd
