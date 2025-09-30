#!/usr/bin/env bash
set -euo pipefail

ASG_NAME="${1:-}"
if [[ -z "$ASG_NAME" ]]; then
  echo "Usage: $0 <ASG_NAME>"
  echo "Hint: terraform output -raw asg_name"
  exit 1
fi

IDS=$(aws autoscaling describe-auto-scaling-groups   --auto-scaling-group-names "$ASG_NAME"   --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text)

if [[ -z "$IDS" ]]; then
  echo "No instances found."
  exit 1
fi

ID=$(echo "$IDS" | awk '{print $1}')
aws ec2 terminate-instances --instance-ids "$ID" >/dev/null
echo "Terminated $ID. ASG will launch a replacement."
