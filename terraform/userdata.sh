#!/bin/sh

# install required packages
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl
mv kubectl /usr/local/bin
chmod +x /usr/local/bin/kubectl

# log into EKS cluster
su - ec2-user -c "aws --region ${region} eks update-kubeconfig --name ${cluster_name}"
