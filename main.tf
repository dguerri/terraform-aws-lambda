terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "terraform_test"
  region  = "eu-west-2"
}

data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-python/"
  output_path = "${var.name_prefix}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = "${var.name_prefix}.zip"
  function_name    = var.name_prefix
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  runtime          = "python3.9"
}

resource "aws_lambda_event_source_mapping" "lambda_via_sqs" {
  batch_size       = var.sqs_batch_size
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = var.name_prefix

  depends_on = [
    aws_lambda_function.lambda_function
  ]
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "lambda_sqs_dead_letter_queue"
  message_retention_seconds = var.sqs_retention_seconds
}

resource "aws_sqs_queue" "lambda_queue" {
  name                      = "lambda_queue"
  message_retention_seconds = var.sqs_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.sqs_max_retry_count
  })
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.dead_letter_queue.arn]
  })
}

resource "aws_cloudwatch_log_group" "test_cloudwatch_log_group" {
  name              = "/aws/lambda/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}
