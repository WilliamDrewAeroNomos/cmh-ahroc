#!/bin/bash
echo "Executing base image setup"

echo "Update the image to the latest patches"

sudo yum install epel-release -y
sudo yum update -y

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

. ~/.nvm/nvm.sh

nvm install node

node -e "console.log('Running Node.js ' + process.version)"

sudo yum install git -y

git clone https://github.com/WilliamDrewAeroNomos/test-node-app.git

cd test-node-app
 
npm install
 
npm install pm2 -g

pm2 start index.js
 
