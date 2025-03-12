variable "aws_region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket for storing audio"
  default     = "wnbui-audio-app-bucket"
}

variable "lambda_function_name" {
  description = "Lambda function name"
  default     = "audio-upload-lambda"
}
