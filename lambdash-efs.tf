variable "aws_region" {
    default = "us-west-2"
}

variable "function_name" {
    default = "lambdash"
}

provider "aws" {
    region          = var.aws_region
}

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "index.js"
    output_path   = "lambdash.zip"
}

resource "aws_lambda_function" "lambdash_efs" {
    filename         = "lambdash.zip"
    function_name    = var.function_name
    role             = "${aws_iam_role.lambdash_efs_role.arn}"
    handler          = "index.handler"
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
    runtime          = "nodejs12.x"
    memory_size      = 256
    timeout          = 60
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
}
