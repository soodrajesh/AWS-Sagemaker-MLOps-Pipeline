#!/bin/bash
set -e

echo "Building and pushing Docker image to ECR..."

# Get ECR repo URI from Terraform output
ECR_URI=$(terraform output -raw ecr_repository_uri)
echo "Using ECR repository: $ECR_URI"

# Get AWS account ID and region
 j``ACCOUNT_ID=$(aws sts get-caller-identity --profile raj-private --query Account --output text)
REGION="eu-west-1"

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $REGION --profile raj-private | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t sagemaker-pytorch-mnist .

# Tag and push to ECR
echo "Tagging and pushing to ECR..."
docker tag sagemaker-pytorch-mnist:latest $ECR_URI:latest
docker push $ECR_URI:latest

echo "Docker image build and push completed!"
