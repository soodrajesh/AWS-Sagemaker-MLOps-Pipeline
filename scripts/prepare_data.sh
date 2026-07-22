#!/bin/bash
set -e

echo "Preparing and uploading MNIST data to S3..."

# Get S3 bucket name from Terraform output
BUCKET=$(terraform output -raw s3_bucket_name)
echo "Using S3 bucket: $BUCKET"

# Create a Python script to upload MNIST data
cat > upload_mnist.py << 'EOF'
import sagemaker
import boto3
from torchvision import datasets
import os
import numpy as np
import sys

def upload_mnist_to_s3(bucket, prefix='mnist'):
    print(f"Downloading MNIST dataset...")
    os.makedirs('mnist', exist_ok=True)
    datasets.MNIST('mnist', train=True, download=True)
    datasets.MNIST('mnist', train=False, download=True)
    
    print(f"Processing MNIST data...")
    # Load MNIST data
    train_data = datasets.MNIST('mnist', train=True, download=False).data.numpy()
    train_labels = datasets.MNIST('mnist', train=True, download=False).targets.numpy()
    test_data = datasets.MNIST('mnist', train=False, download=False).data.numpy()
    test_labels = datasets.MNIST('mnist', train=False, download=False).targets.numpy()
    
    # Save as numpy arrays
    np.save('mnist/train_data.npy', train_data)
    np.save('mnist/train_labels.npy', train_labels)
    np.save('mnist/test_data.npy', test_data)
    np.save('mnist/test_labels.npy', test_labels)
    
    print(f"Uploading to S3 bucket: {bucket}")
    # Create SageMaker session with explicit region and profile
    boto_session = boto3.Session(region_name='eu-west-1', profile_name='raj-private')
    sagemaker_session = sagemaker.Session(boto_session=boto_session)
    sagemaker_session.upload_data('mnist/train_data.npy', bucket=bucket, key_prefix=f'{prefix}/train')
    sagemaker_session.upload_data('mnist/train_labels.npy', bucket=bucket, key_prefix=f'{prefix}/train')
    sagemaker_session.upload_data('mnist/test_data.npy', bucket=bucket, key_prefix=f'{prefix}/validation')
    sagemaker_session.upload_data('mnist/test_labels.npy', bucket=bucket, key_prefix=f'{prefix}/validation')
    
    print("MNIST data upload completed!")

if __name__ == "__main__":
    bucket = sys.argv[1]
    upload_mnist_to_s3(bucket)
EOF

# Run the upload script
python3 upload_mnist.py "$BUCKET"

# Clean up
rm upload_mnist.py
rm -rf mnist

echo "Data preparation completed!"
