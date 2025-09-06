variable "vpc_id" {
  description = "VPC ID for the notebook instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the notebook instance"
  type        = string
}

variable "notebook_instance_name" {
  description = "Name for the SageMaker notebook instance"
  type        = string
}

variable "notebook_instance_type" {
  description = "Instance type for the SageMaker notebook instance"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for the SageMaker notebook instance"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting the notebook instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the notebook instance and related resources"
  type        = map(string)
}
