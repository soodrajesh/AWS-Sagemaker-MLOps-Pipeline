# SageMaker ML Workflow Automation

This document describes the automated shell scripts that make the SageMaker ML workflow fully automated and easy to run.

## Quick Start (Fully Automated)

1. **Prerequisites:**
   - Install [Terraform](https://www.terraform.io/downloads.html)
   - Install [Docker](https://docs.docker.com/get-docker/)
   - Configure AWS CLI with the `raj-private` profile
   - Edit `terraform.tfvars` with your VPC, subnet, and other variables

2. **Run the complete workflow:**
   ```bash
   ./deploy_and_train.sh
   ```

3. **Clean up when finished:**
   ```bash
   ./scripts/cleanup.sh
   ```

## Available Scripts

### Main Orchestration Script
- **`deploy_and_train.sh`** - Runs the complete workflow:
  1. Deploy infrastructure with Terraform
  2. Prepare and upload MNIST data to S3
  3. Build and push Docker image to ECR
  4. Train both XGBoost and PyTorch models

### Individual Scripts
- **`scripts/prepare_data.sh`** - Downloads MNIST dataset and uploads to S3
- **`scripts/build_and_push_docker.sh`** - Builds and pushes PyTorch Docker image to ECR
- **`scripts/train_models.sh`** - Triggers SageMaker training jobs for both models
- **`scripts/cleanup.sh`** - Stops notebook instance and destroys infrastructure

## Usage Examples

### Run Individual Steps
```bash
# Deploy infrastructure only
terraform init && terraform apply -auto-approve

# Prepare data only
./scripts/prepare_data.sh

# Build and push Docker image only
./scripts/build_and_push_docker.sh

# Train models only
./scripts/train_models.sh

# Clean up only
./scripts/cleanup.sh
```

### Monitor Progress
- Check AWS Console → SageMaker → Training jobs
- Check AWS Console → SageMaker → Hyperparameter tuning jobs
- Check AWS Console → S3 for model artifacts
- Check AWS Console → ECR for Docker images

## Script Details

### `deploy_and_train.sh`
- Main entry point for the complete workflow
- Automatically reads Terraform outputs for S3 bucket and ECR repository
- Runs all steps sequentially with error handling

### `scripts/prepare_data.sh`
- Downloads MNIST dataset using PyTorch
- Processes and saves data as numpy arrays
- Uploads to S3 using SageMaker session
- Uses Terraform output for S3 bucket name

### `scripts/build_and_push_docker.sh`
- Authenticates Docker to ECR
- Builds PyTorch Docker image
- Tags and pushes to ECR repository
- Uses Terraform output for ECR repository URI

### `scripts/train_models.sh`
- Creates and runs SageMaker training jobs
- Configures hyperparameter tuning (3 jobs, 1 parallel)
- Uses Terraform outputs for S3 bucket and ECR repository
- Trains both XGBoost and PyTorch models

### `scripts/cleanup.sh`
- Stops SageMaker notebook instance
- Destroys all Terraform infrastructure
- Provides cleanup completion message

## Error Handling

All scripts use `set -e` to exit immediately if any command fails. This ensures that:
- The workflow stops if any step fails
- You can identify and fix issues before proceeding
- Resources are not left in an inconsistent state

## Customization

### Modify Training Parameters
Edit the hyperparameter ranges in `scripts/train_models.sh`:
```bash
# XGBoost hyperparameters
hyperparameter_ranges = {
    'max_depth': sagemaker.tuner.IntegerParameter(3, 10),
    'eta': sagemaker.tuner.ContinuousParameter(0.1, 0.5),
    'num_round': sagemaker.tuner.IntegerParameter(100, 1000)
}

# PyTorch hyperparameters
hyperparameter_ranges = {
    'lr': sagemaker.tuner.ContinuousParameter(0.0001, 0.1),
    'batch-size': sagemaker.tuner.IntegerParameter(32, 256),
    'epochs': sagemaker.tuner.IntegerParameter(5, 15)
}
```

### Modify Instance Types
Change instance types in the scripts (ensure they're Free Tier eligible):
```bash
instance_type='ml.t2.medium'  # Free Tier eligible
```

## Troubleshooting

### Common Issues
1. **AWS credentials not configured:** Ensure `raj-private` profile is set up
2. **Docker not running:** Start Docker daemon before running scripts
3. **Terraform state issues:** Run `terraform init` if you get state errors
4. **ECR authentication fails:** Check AWS credentials and region settings

### Debug Mode
Add `set -x` to any script to see detailed command execution:
```bash
#!/bin/bash
set -e
set -x  # Enable debug mode
```

## Free Tier Compliance

The scripts are designed to stay within AWS Free Tier limits:
- Uses `ml.t2.medium` instances (50 hours/month for notebook and training)
- Limits hyperparameter tuning to 3 jobs, 1 parallel
- Minimal storage usage for S3 and ECR
- Automatic cleanup to avoid ongoing charges

## Next Steps

After running the automated workflow:
1. Monitor training jobs in the AWS Console
2. Compare model performance results
3. Run `./scripts/cleanup.sh` when finished
4. Check AWS Billing Dashboard to ensure Free Tier compliance
