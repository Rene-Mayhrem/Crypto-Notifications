
provider "aws" {
  region = "us-west-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_sns_role"
  assume_role_policy = jsondecode({
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

resource "aws_iam_policy" "sns_publish_policy" {
  name = "sns_publish_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = "arn:aws:sns:us-west-2:ACCOUNT_ID:gd_topic"
      }
    ]
  }) 
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

resource "aws_sns_topic" "nba_game_notifications" {
  name = "NBA_Game_Notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.nba_game_notifications.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

resource "aws_lambda_function" "nba_game_notifications_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "NBA_Game_Notifications"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      NBA_API_KEY   = var.NBA_API_KEY
      SNS_TOPIC_ARN = aws_sns_topic.nba_game_notifications.arn
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nba_game_notifications_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.nba_game_notifications.arn
}

variable NBA_API_KEY {
  type = string
}