variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "s3_bucket_base_name" {
  description = "Base name for S3 bucket"
  default     = "my-audio-app"
}
