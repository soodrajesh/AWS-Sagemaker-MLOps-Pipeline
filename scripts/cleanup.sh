#!/bin/bash
set -e

echo "Starting cleanup process..."

# Get notebook instance name from Terraform output
NOTEBOOK_NAME=$(terraform output -raw notebook_instance_name 2>/dev/null || echo "MNISTNotebookInstance")

echo "Stopping SageMaker notebook instance: $NOTEBOOK_NAME"
# Stop notebook instance (ignore errors if already stopped)
aws sagemaker stop-notebook-instance --notebook-instance-name "$NOTEBOOK_NAME" 2>/dev/null || echo "Notebook instance already stopped or doesn't exist"

echo "Waiting for notebook instance to stop..."
# Wait for notebook to stop
aws sagemaker wait notebook-instance-stopped --notebook-instance-name "$NOTEBOOK_NAME" 2>/dev/null || echo "Notebook instance stop completed or doesn't exist"

echo "Destroying Terraform infrastructure..."
# Destroy infrastructure
terraform destroy -auto-approve

echo "Cleanup completed!"
echo "Note: You may need to manually delete any remaining S3 objects or ECR images if they weren't removed by Terraform."
