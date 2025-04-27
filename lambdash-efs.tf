variable "function_name" {
  default = "lambdash"
}

variable "fsap" {
  description = "EFS Access Point (fsap-xxxx)"
}

variable "subnet" {
  description = "subnet with reachable EFS mount target (subnet-xxxx)"
}

variable "sg" {
  description = "security group with reachable EFS mount target (sg-xxxx)"
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  runtime          = "nodejs18.x"
  memory_size      = 256
  timeout          = 60

  file_system_config {
    arn              = "arn:aws:elasticfilesystem:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-point/${var.fsap}"
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    subnet_ids         = [var.subnet]
    security_group_ids = [var.sg]
  }
}

resource "aws_iam_role" "lambdash_efs_role" {
  name = "lambdash_efs"

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
}

// Attach managed policies to the role via dedicated attachments
resource "aws_iam_role_policy_attachment" "lambdash_vpc_access" {
  role       = aws_iam_role.lambdash_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambdash_efs_rw" {
  role       = aws_iam_role.lambdash_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}
