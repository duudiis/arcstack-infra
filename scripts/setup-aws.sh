#!/bin/bash
set -euo pipefail

# =============================================================================
# ArcStack AWS Setup Script
# Creates the EC2 prerequisites needed for Arc instance provisioning:
#   - Security group (allows SSH + outbound for agent WS connection)
#   - Key pair (for SSH access to instances)
#   - Finds the latest Ubuntu 22.04 AMI
# =============================================================================

REGION="${AWS_REGION:-us-east-1}"
VPC_ID="${AWS_VPC_ID:-}"  # Leave empty to use default VPC
PROJECT="arcstack"

echo "=== ArcStack AWS Setup ==="
echo "Region: $REGION"

# ---------- Default VPC ----------
if [ -z "$VPC_ID" ]; then
  VPC_ID=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text)
  echo "Using default VPC: $VPC_ID"
fi

# ---------- Subnet ----------
SUBNET_ID=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[0].SubnetId" \
  --output text)
echo "Subnet: $SUBNET_ID"

# ---------- Security Group ----------
SG_NAME="${PROJECT}-agent-sg"
EXISTING_SG=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "None")

if [ "$EXISTING_SG" != "None" ] && [ -n "$EXISTING_SG" ]; then
  SG_ID="$EXISTING_SG"
  echo "Security group already exists: $SG_ID"
else
  SG_ID=$(aws ec2 create-security-group \
    --region "$REGION" \
    --group-name "$SG_NAME" \
    --description "ArcStack agent instances — SSH + outbound WS" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" \
    --output text)

  # Allow SSH from anywhere (for debugging; restrict in production)
  aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SG_ID" \
    --protocol tcp --port 22 --cidr 0.0.0.0/0

  # All outbound is allowed by default (agent needs to connect to API via WS)

  aws ec2 create-tags \
    --region "$REGION" \
    --resources "$SG_ID" \
    --tags "Key=ManagedBy,Value=arcstack"

  echo "Created security group: $SG_ID"
fi

# ---------- Key Pair ----------
KEY_NAME="${PROJECT}-key"
KEY_FILE="${KEY_NAME}.pem"

EXISTING_KEY=$(aws ec2 describe-key-pairs \
  --region "$REGION" \
  --key-names "$KEY_NAME" \
  --query "KeyPairs[0].KeyName" \
  --output text 2>/dev/null || echo "None")

if [ "$EXISTING_KEY" != "None" ] && [ -n "$EXISTING_KEY" ]; then
  echo "Key pair already exists: $KEY_NAME"
else
  aws ec2 create-key-pair \
    --region "$REGION" \
    --key-name "$KEY_NAME" \
    --query "KeyMaterial" \
    --output text > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
  echo "Created key pair: $KEY_NAME (saved to $KEY_FILE)"
fi

# ---------- AMI (Ubuntu 22.04 LTS) ----------
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)
echo "Latest Ubuntu 22.04 AMI: $AMI_ID"

# ---------- Summary ----------
echo ""
echo "=== Add these to your .env ==="
echo "AWS_REGION=$REGION"
echo "AWS_AMI_ID=$AMI_ID"
echo "AWS_SECURITY_GROUP_ID=$SG_ID"
echo "AWS_SUBNET_ID=$SUBNET_ID"
echo "AWS_KEY_PAIR_NAME=$KEY_NAME"
echo "AWS_INSTANCE_TYPE=t2.micro"
