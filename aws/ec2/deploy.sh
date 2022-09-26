#!/bin/sh
set -e

if [[ $# -ne 1 ]]; then
    echo "Error: Unsupported number of arguments."
    echo
    echo "USAGE:"
    echo "  deploy.sh <region>"
    echo
    echo "WHERE:"
    echo "  region  The name of the AWS region where the server will be placed,"
    echo "          e.g. eu-west-1, us-east-1, etc."
    exit 1
fi

region=$1
valid_regions=(
    "eu-north-1"
    "ap-south-1"
    "eu-west-3"
    "eu-west-2"
    "eu-west-1"
    "ap-northeast-3"
    "ap-northeast-2"
    "ap-northeast-1"
    "sa-east-1"
    "ca-central-1"
    "ap-southeast-1"
    "ap-southeast-2"
    "eu-central-1"
    "us-east-1"
    "us-east-2"
    "us-west-1"
    "us-west-2"
)

if [[ ! " ${valid_regions[*]} " =~ [[:space:]]${region}[[:space:]] ]]; then
  echo "Invalid region $region specified. Use a valid AWS region."
  exit 1
fi

echo "Querying for own IP, this will be used to restrict access to server"
safeLocation="$(curl api.ipify.org)/32"

echo "Fetching latest Amazon Linux 2 AMI in region $region ..."
ami=$(aws ssm get-parameters \
    --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --region $region \
    --query 'Parameters[0].Value' \
    --output text)
echo "... got AMI ID $ami"

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
        SafeLocation=$safeLocation \
        ImageAmiId=$ami

publicIp=$(aws cloudformation describe-stacks \
    --stack-name minecraft \
    --query 'Stacks[].Outputs[][].OutputValue' \
    --output text)

echo "Connect by SSH to the instance with"
echo
echo "ssh -i $keyPairName.pem ec2-user@$publicIp"