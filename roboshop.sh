#!/bin/bash

SG_ID="sg-0978bd3e9e6d67ee8"
AMI_ID="ami-0220d79f3f480ecf5"

for instance in $@
do
   INSTANCEID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type "t3.micro" \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    if [ $instance == "frontend" ]; then
            IP=$(aws ec2 describe-instances \
                --instance-ids $INSTANCEID \
                --query "Reservations[].Instances[].PublicIpAddress" \
                --output text
            )
        else
            IP=$(aws ec2 describe-instances \
                --instance-ids $InstanceID \
                --query "Reservations[].Instances[].PrivateIpAddress" \
                --output text
            )
    fi

    echo "IP Address: $IP"
done
