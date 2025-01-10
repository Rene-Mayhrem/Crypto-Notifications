provider "aws" {
  region = var.region
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_sns_role_${random_string.suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "random_string" "suffix" {
  length = 8
  special = false
}

data "template_file" "sns_publish_policy" {
  template = file("${path.module}/policies/gd_notifications.json")
  vars = {
    region     = var.region 
    account_id = var.account_id 
    topic      = var.topic
  }
}

resource "aws_iam_policy" "sns_publish_policy" {
  name   = "sns_publish_policy_${random_string.suffix.result}"
  policy = data.template_file.sns_publish_policy.rendered
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

resource "aws_sns_topic" "crypto_notifications" {
  name = var.topic 
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.crypto_notifications.arn
  protocol  = "email"
  endpoint  = "your-email"
}

resource "aws_lambda_function" "crypto_notifications_lambda" {
  filename         = "${path.module}/src/lambda_function.zip"
  function_name    = "lambda_api_notification"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/src/lambda_function.zip")
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.crypto_notifications.arn
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crypto_notifications_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.crypto_notifications.arn
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type = string
}

variable "account_id" {
  description = "The AWS account ID"
  type = string
}

variable topic {
  description = "The name of the SNS topic"
  type = string
}