# S3 Bucket for storing dataset and model artifacts
resource "aws_s3_bucket" "mnist_bucket" {
  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : "sagemaker-mnist-data-${random_string.bucket_suffix.result}"
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "mnist_bucket_versioning" {
  bucket = aws_s3_bucket.mnist_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for SageMaker
resource "aws_iam_role" "sagemaker_role" {
  name = var.sagemaker_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_policy" {
  name = "SageMakerFreeTierPolicy"
  role = aws_iam_role.sagemaker_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "sagemaker:CreateNotebookInstance",
          "sagemaker:DeleteNotebookInstance",
          "sagemaker:StartNotebookInstance",
          "sagemaker:StopNotebookInstance",
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateHyperParameterTuningJob",
          "sagemaker:DescribeHyperParameterTuningJob",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# SageMaker Notebook Instance Lifecycle Configuration
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "mnist_lifecycle_config" {
  name = "MNISTLifecycleConfig"
  on_create = base64encode(<<EOF
#!/bin/bash
pip install torch torchvision
mkdir -p /home/ec2-user/SageMaker/mnist
wget -P /home/ec2-user/SageMaker/mnist https://raw.githubusercontent.com/pytorch/examples/main/mnist/main.py
EOF
  )
}

# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "mnist_notebook" {
  name                  = "MNISTNotebookInstance"
  instance_type         = var.notebook_instance_type
  role_arn              = aws_iam_role.sagemaker_role.arn
  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.mnist_lifecycle_config.name
  volume_size           = 5  # Minimum size, Free Tier eligible
}

# ECR Repository for custom PyTorch algorithm
resource "aws_ecr_repository" "pytorch_repository" {
  name = var.ecr_repository_name
}

resource "aws_ecr_repository_policy" "pytorch_repository_policy" {
  repository = aws_ecr_repository.pytorch_repository.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}