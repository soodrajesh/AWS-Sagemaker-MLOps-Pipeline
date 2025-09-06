resource "aws_sagemaker_notebook_instance" "this" {
  name          = var.notebook_instance_name
  instance_type = var.notebook_instance_type
  role_arn      = var.role_arn
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.notebook_sg.id]
  kms_key_id    = var.kms_key_id
  tags          = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "notebook_sg" {
  name        = "notebook-sg-${var.notebook_instance_name}"
  description = "Security group for SageMaker notebook instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS access (restrict in production)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
