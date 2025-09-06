output "notebook_instance_name" {
  description = "Name of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.name
}

output "notebook_instance_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.arn
}

output "notebook_instance_url" {
  description = "URL to access the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.this.url
}
