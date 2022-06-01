variable "name_prefix" {
  default = "test-lambda-function"
}

variable "sqs_batch_size" {
  default = 10
}

variable "sqs_retention_seconds" {
  default = 1209600
}

variable "sqs_max_retry_count" {
  default = 4
}

variable "log_retention_days" {
  default = 14
}