variable "vpc_id" {
  description = "VPC ID for SageMaker resources"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for SageMaker notebook instance"
  type        = string
}

variable "notebook_instance_name" {
  description = "Name for the SageMaker notebook instance"
  type        = string
  default     = "sagemaker-notebook"
}

variable "notebook_role_arn" {
  description = "IAM role ARN for the SageMaker notebook instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_name" {
  description = "S3 bucket for storing MNIST dataset and model artifacts"
  type        = string
  default     = ""
}

variable "sagemaker_role_name" {
  description = "Name of the IAM role for SageMaker"
  type        = string
  default     = "SageMakerExecutionRole"
}

variable "notebook_instance_type" {
  description = "SageMaker Notebook Instance Type"
  type        = string
  default     = "ml.t2.medium"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for custom PyTorch algorithm"
  type        = string
  default     = "sagemaker-pytorch-mnist"
}
