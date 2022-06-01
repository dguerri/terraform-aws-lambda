data "aws_iam_policy_document" "lambda_logging_policy" {
  statement {
    sid = "EnableLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_sqs_policy_document" {
  statement {
    sid = "ProcessSQSMessages"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.lambda_queue.arn]
  }
}

data "aws_iam_policy_document" "lambda_execution_policy_document" {
  statement {
    sid     = "AllowLambdaToAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Role for lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.name_prefix}_role"
  # Grant lambda permission to assume the role "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy_document.json
}

# Attach policies (logging + sqs message receive)
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name   = "lambda_sqs_policy"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.lambda_sqs_policy_document.json
}

resource "aws_iam_role_policy" "lambda_logs_policy" {
  name   = "lambda_logs_policy"
  role   = aws_iam_role.iam_for_lambda.name
  policy = data.aws_iam_policy_document.lambda_logging_policy.json
}
