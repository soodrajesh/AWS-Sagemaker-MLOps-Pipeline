import sagemaker
from sagemaker import get_execution_role
from sagemaker.xgboost import XGBoost
from sagemaker.tuner import HyperparameterTuner
import boto3

# Initialize SageMaker session and role
sagemaker_session = sagemaker.Session()
role = get_execution_role()
bucket = 'sagemaker-mnist-data'  # Replace with your S3 bucket

# Define S3 paths for MNIST dataset
train_input = f's3://{bucket}/mnist/train'
validation_input = f's3://{bucket}/mnist/validation'

# Download and upload MNIST dataset to S3
from torchvision import datasets, transforms
import os
import numpy as np

def upload_mnist_to_s3(bucket, prefix='mnist'):
    os.makedirs('mnist', exist_ok=True)
    datasets.MNIST('mnist', train=True, download=True)
    datasets.MNIST('mnist', train=False, download=True)
    
    train_data = np.load('mnist/MNIST/raw/train-images-idx3-ubyte.npy')
    train_labels = np.load('mnist/MNIST/raw/train-labels-idx1-ubyte.npy')
    test_data = np.load('mnist/MNIST/raw/t10k-images-idx3-ubyte.npy')
    test_labels = np.load('mnist/MNIST/raw/t10k-labels-idx1-ubyte.npy')
    
    np.save('mnist/train_data.npy', train_data)
    np.save('mnist/train_labels.npy', train_labels)
    np.save('mnist/test_data.npy', test_data)
    np.save('mnist/test_labels.npy', test_labels)
    
    sagemaker_session.upload_data('mnist/train_data.npy', bucket=bucket, key_prefix=f'{prefix}/train')
    sagemaker_session.upload_data('mnist/train_labels.npy', bucket=bucket, key_prefix=f'{prefix}/train')
    sagemaker_session.upload_data('mnist/test_data.npy', bucket=bucket, key_prefix=f'{prefix}/validation')
    sagemaker_session.upload_data('mnist/test_labels.npy', bucket=bucket, key_prefix=f'{prefix}/validation')

# Upload MNIST data
upload_mnist_to_s3(bucket)

# Define XGBoost estimator
xgboost_estimator = XGBoost(
    entry_point='train_xgboost.py',  # This script itself
    role=role,
    instance_count=1,
    instance_type='ml.t2.medium',  # Free Tier eligible
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
    max_jobs=3,  # Reduced for Free Tier
    max_parallel_jobs=1  # Reduced for Free Tier
)

# Start training job
xgboost_estimator.fit({'train': train_input, 'validation': validation_input})

# Start hyperparameter tuning job
tuner.fit({'train': train_input, 'validation': validation_input})