variable "aws_region" {
  default = "us-west-2"
}

variable "function_name" {
  default = "lambdash"
}

variable "fsap_arn" {
  description = "EFS Access Point ARN"
}

variable "subnet_id" {
  description = "subnet ID with reachable EFS mount target"
}

variable "security_group_id" {
  description = "security group ID with reachable EFS mount target"
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.js"
  output_path = "lambdash.zip"
}

resource "aws_lambda_function" "lambdash_efs" {
  filename         = "lambdash.zip"
  function_name    = var.function_name
  role             = aws_iam_role.lambdash_efs_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs14.x"
  memory_size      = 256
  timeout          = 60

  file_system_config {
    arn              = var.fsap_arn
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.security_group_id]
  }
}

resource "aws_iam_role" "lambdash_efs_role" {
  name = "iam_for_lambda_tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess",
  ]
}
