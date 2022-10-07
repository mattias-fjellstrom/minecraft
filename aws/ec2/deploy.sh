#!/bin/sh
set -e

echo "Querying for own IP, this will be used to restrict access to server"
safeLocation="$(curl api.ipify.org)/32"

echo "Getting the current selected region for the CLI profile"
region=$(aws configure get region)
echo "Got region $region"

keyPairName=mc-aws-ec2-$region
echo "Checking if key pair with the name $keyPairName in region $region exists ..."
keyMaterial=$(aws ec2 describe-key-pairs \
    --filters "Name=key-name,Values=$keyPairName" \
    --query 'KeyPairs[0].KeyName')
if [[ ! -z "$keyMaterial" ]]; then
    echo "Deleting old key pair with the name $keyPairName in region $region ..."
    aws ec2 delete-key-pair --key-name $keyPairName
fi

echo "Creating new key pair with the name $keyPairName in region $region ..."
keyMaterial=$(aws ec2 create-key-pair \
    --key-name $keyPairName \
    --query KeyMaterial \
    --output text)
echo "Storing private key in a local file ..."
rm -f $keyPairName.pem
echo "$keyMaterial" > $keyPairName.pem
chmod 400 $keyPairName.pem

aws cloudformation deploy \
    --template-file template.yaml \
    --region $region \
    --stack-name minecraft \
    --parameter-overrides \
        KeyName=$keyPairName \
        SafeLocation=$safeLocation

publicIp=$(aws cloudformation describe-stacks \
    --stack-name minecraft \
    --query 'Stacks[].Outputs[0].OutputValue' \
    --output text)
publicDNS=$(aws cloudformation describe-stacks \
    --stack-name minecraft \
    --query 'Stacks[].Outputs[1].OutputValue' \
    --output text)

echo "Connect by SSH to the instance with"
echo
echo "ssh -i $keyPairName.pem ec2-user@$publicIp"
echo "or"
echo "ssh -i $keyPairName.pem ec2-user@$publicDNS"
echo
echo "Connect your Minecraft client to"
echo
echo "$publicDNS"