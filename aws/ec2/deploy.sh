#!/bin/sh
set -e

aws cloudformation deploy \
    --template-file template.yaml \
    --region eu-west-1 \
    --stack-name minecraft

publicIp=$(aws cloudformation describe-stacks \
    --stack-name minecraft \
    --query 'Stacks[].Outputs[][].OutputValue' \
    --output text)

echo $publicIp