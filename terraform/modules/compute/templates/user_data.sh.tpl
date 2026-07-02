#!/bin/bash
set -euo pipefail

# Redirect output to log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/null) 2>&1

echo "Starting User Data script..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io unzip awscli

systemctl start docker
systemctl enable docker

echo "Discovering Redis Sentinel endpoints..."
REDIS_IPs=""
for i in {1..30}; do
  REDIS_IPs=$(aws ec2 describe-instances \
    --region ${region} \
    --filters "Name=tag:Project,Values=${project_name}" "Name=tag:Role,Values=redis" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].PrivateIpAddress" \
    --output text)
  if [ -n "$REDIS_IPs" ]; then
    break
  fi
  echo "Waiting for Redis instances to become available (attempt $i)..."
  sleep 10
done

if [ -z "$REDIS_IPs" ]; then
  echo "ERROR: No Redis instances found!"
  exit 1
fi

# Format Sentinel endpoints as host1:26379
SENTINELS=""
for ip in $REDIS_IPs; do
  if [ -z "$SENTINELS" ]; then
    SENTINELS="$ip:26379"
  else
    SENTINELS="$SENTINELS,$ip:26379"
  fi
done

echo "Found Sentinels: $SENTINELS"

# Run app container
docker run -d \
  --name carbonfire-app \
  --restart always \
  -p 80:3000 \
  -e REDIS_SENTINELS="$SENTINELS" \
  -e REDIS_MASTER_NAME="mymaster" \
  -e PORT="3000" \
  itzboncar/carbonfire:latest

echo "User Data script finished successfully!"
