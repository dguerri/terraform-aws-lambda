output "zipfile_base64sha256" {
  value = data.archive_file.lambda_function_zip.output_base64sha256
}

output "sqs_arn" {
  value = aws_sqs_queue.lambda_queue.arn
}

output "lambda_arn" {
  value = aws_lambda_function.lambda_function.arn
}
