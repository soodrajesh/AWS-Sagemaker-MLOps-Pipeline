#!/bin/bash
set -e

echo "Starting SageMaker ML Workflow..."

# 1. Deploy infrastructure
echo "Deploying infrastructure..."
terraform init
terraform apply -auto-approve

# 2. Prepare data
echo "Preparing and uploading MNIST data..."
./scripts/prepare_data.sh

# 3. Build and push Docker image
echo "Building and pushing Docker image..."
./scripts/build_and_push_docker.sh

# 4. Train models
echo "Training models..."
./scripts/train_models.sh

echo "Workflow complete!"
