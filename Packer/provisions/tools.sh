#!/bin/sh -eux

apt-get -y install unzip gnupg software-properties-common vim

TMP_DIR="/tmp/temporal"

mkdir -p $TMP_DIR
cd $TMP_DIR

echo "Installing AWS Cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "./awscliv2.zip"

unzip awscliv2.zip
sudo ./aws/install

echo "Installing Azure Cli"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Installing Google Cloud Platform"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get -y install google-cloud-sdk


echo "Installing Hashicorp tools"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get -y install terraform packer vault

apt-get -y remove --purge unzip
rm -fr $TMP_DIR