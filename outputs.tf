output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.mnist_notebook.arn
}

output "notebook_instance_url" {
  description = "URL to access the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.mnist_notebook.url
}

output "s3_bucket_name" {
  description = "S3 Bucket for storing data and artifacts"
  value       = aws_s3_bucket.mnist_bucket.bucket
}

output "ecr_repository_uri" {
  description = "URI of the ECR Repository"
  value       = aws_ecr_repository.pytorch_repository.repository_url
}

output "sagemaker_role_arn" {
  description = "ARN of the SageMaker Execution Role"
  value       = aws_iam_role.sagemaker_role.arn
}
