output "s3_bucket_name" {
  description = "S3 bucket where audio files are stored"
  value       = aws_s3_bucket.audio_bucket.id
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.audio_lambda.arn
}

output "api_gateway_url" {
  description = "API Gateway URL for audio upload"
  value       = aws_apigatewayv2_api.api.api_endpoint
}
