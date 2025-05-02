output "s3_bucket_name" {
  description = "S3 bucket where audio files are stored"
  value       = aws_s3_bucket.audio_bucket.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing transcription jobs"
  value       = aws_dynamodb_table.transcriptions_table.name
}

output "api_gateway_url" {
  description = "API Gateway URL for audio upload"
  value       = aws_apigatewayv2_api.api.api_endpoint
}
