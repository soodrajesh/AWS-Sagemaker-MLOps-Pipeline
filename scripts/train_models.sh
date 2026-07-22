#!/bin/bash
set -e

echo "Starting model training..."

# Get S3 bucket, ECR repo URI, and SageMaker role ARN from Terraform output
BUCKET=$(terraform output -raw s3_bucket_name)
ECR_URI=$(terraform output -raw ecr_repository_uri)
ROLE_ARN=$(terraform output -raw sagemaker_role_arn)
echo "Using S3 bucket: $BUCKET"
echo "Using ECR repository: $ECR_URI"
echo "Using SageMaker role: $ROLE_ARN"

# Create a Python script to run training jobs
cat > run_training.py << 'EOF'
import sagemaker
import boto3
from sagemaker import get_execution_role
from sagemaker.xgboost import XGBoost
from sagemaker.pytorch import PyTorch
from sagemaker.tuner import HyperparameterTuner
import sys

def train_xgboost(bucket, role_arn):
    print("Training XGBoost model...")
    
    # Initialize SageMaker session and role
    boto_session = boto3.Session(region_name='eu-west-1', profile_name='raj-private')
    sagemaker_session = sagemaker.Session(boto_session=boto_session)
    role = role_arn
    
    # Define S3 paths for MNIST dataset
    train_input = f's3://{bucket}/mnist/train'
    validation_input = f's3://{bucket}/mnist/validation'
    
    # Define XGBoost estimator
    xgboost_estimator = XGBoost(
        entry_point='train_xgboost_sagemaker.py',
        role=role,
        instance_count=1,
        instance_type='ml.m5.large',
        framework_version='1.7-1',
        py_version='py3',
        output_path=f's3://{bucket}/output',
        sagemaker_session=sagemaker_session
    )
    
    # Define hyperparameter ranges for tuning
    hyperparameter_ranges = {
        'max_depth': sagemaker.tuner.IntegerParameter(3, 10),
        'eta': sagemaker.tuner.ContinuousParameter(0.1, 0.5),
        'num_round': sagemaker.tuner.IntegerParameter(100, 1000)
    }
    
    # Configure hyperparameter tuning job
    tuner = HyperparameterTuner(
        estimator=xgboost_estimator,
        objective_metric_name='validation:accuracy',
        hyperparameter_ranges=hyperparameter_ranges,
        metric_definitions=[{'Name': 'validation:accuracy', 'Regex': 'validation-accuracy: ([0-9.]+)'}],
        max_jobs=3,
        max_parallel_jobs=1
    )
    
    # Start training and tuning
    print("Starting XGBoost training job...")
    xgboost_estimator.fit({'train': train_input, 'validation': validation_input})
    
    print("Starting XGBoost hyperparameter tuning...")
    tuner.fit({'train': train_input, 'validation': validation_input})
    
    print("XGBoost training completed!")

def train_pytorch(bucket, ecr_uri, role_arn):
    print("Training PyTorch model...")
    
    # Initialize SageMaker session and role
    boto_session = boto3.Session(region_name='eu-west-1', profile_name='raj-private')
    sagemaker_session = sagemaker.Session(boto_session=boto_session)
    role = role_arn
    
    # Define PyTorch estimator
    pytorch_estimator = PyTorch(
        entry_point='train_pytorch.py',
        role=role,
        instance_count=1,
        instance_type='ml.m5.large',
        framework_version='1.9.0',
        py_version='py3',
        source_dir='.',
        image_uri=ecr_uri,
        output_path=f's3://{bucket}/output',
        sagemaker_session=sagemaker_session
    )
    
    # Define hyperparameter ranges for tuning
    hyperparameter_ranges = {
        'lr': sagemaker.tuner.ContinuousParameter(0.0001, 0.1),
        'batch-size': sagemaker.tuner.IntegerParameter(32, 256),
        'epochs': sagemaker.tuner.IntegerParameter(5, 15)
    }
    
    # Configure hyperparameter tuning job
    tuner = HyperparameterTuner(
        estimator=pytorch_estimator,
        objective_metric_name='validation:accuracy',
        hyperparameter_ranges=hyperparameter_ranges,
        metric_definitions=[{'Name': 'validation:accuracy', 'Regex': 'validation-accuracy: ([0-9.]+)'}],
        max_jobs=3,
        max_parallel_jobs=1
    )
    
    # Start training and tuning
    print("Starting PyTorch training job...")
    pytorch_estimator.fit({'training': f's3://{bucket}/mnist'})
    
    print("Starting PyTorch hyperparameter tuning...")
    tuner.fit({'training': f's3://{bucket}/mnist'})
    
    print("PyTorch training completed!")

if __name__ == "__main__":
    bucket = sys.argv[1]
    ecr_uri = sys.argv[2]
    role_arn = sys.argv[3]
    
    train_xgboost(bucket, role_arn)
    train_pytorch(bucket, ecr_uri, role_arn)
    
    print("All training jobs completed!")
EOF

# Run the training script
python3 run_training.py "$BUCKET" "$ECR_URI" "$ROLE_ARN"

# Clean up
rm run_training.py

echo "Model training completed!"
