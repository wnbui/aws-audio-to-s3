resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "audio_bucket" {
  bucket = "${var.s3_bucket_base_name}-${random_id.bucket_id.hex}"
}


resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.audio_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.audio_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_transcribe_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Policy for S3, Transcribe, DynamoDB, CloudWatch
resource "aws_iam_policy" "lambda_permissions_policy" {
  name = "lambda_full_permissions_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource : [
          "arn:aws:s3:::${aws_s3_bucket.audio_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.audio_bucket.id}/*"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "transcribe:StartTranscriptionJob",
          "transcribe:GetTranscriptionJob"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_permissions_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_permissions_policy.arn
}

# First Lambda Function: Upload audio & start transcription
resource "aws_lambda_function" "audio_lambda" {
  filename      = "lambda.zip"
  function_name = "audio-upload-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      BUCKET_NAME         = aws_s3_bucket.audio_bucket.id
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.transcriptions_table.name
    }
  }

  source_code_hash = filebase64sha256("lambda.zip")
}

# Second Lambda Function: Process & store transcription
resource "aws_lambda_function" "process_transcription_lambda" {
  filename      = "process_lambda.zip"
  function_name = "process-transcription-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "process_transcription_lambda.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.transcriptions_table.name
    }
  }

  source_code_hash = filebase64sha256("process_lambda.zip")
}

# Third Lambda Function: Get transcription

resource "aws_lambda_function" "get_transcription_lambda" {
  function_name    = "get-transcription_lambda"
  filename         = "get_transcription_lambda.zip"
  handler          = "get_transcription_lambda.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("get_transcription_lambda.zip")
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.transcriptions_table.name
    }
  }
}

# API Gateway for frontend to upload
resource "aws_apigatewayv2_api" "api" {
  name          = "audio-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# POST /upload
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.audio_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

resource "aws_lambda_permission" "allow_api_upload" {
  statement_id  = "AllowAPIGatewayInvokeUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audio_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/POST/upload"
}

# GET /get-transcription
resource "aws_apigatewayv2_integration" "get_transcription_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_transcription_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_transcription_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /get-transcription"
  target    = "integrations/${aws_apigatewayv2_integration.get_transcription_integration.id}"
}

resource "aws_lambda_permission" "allow_api_get" {
  statement_id  = "AllowAPIGatewayInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_transcription_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/GET/get-transcription"
}

# DynamoDB Table for transcriptions results
resource "aws_dynamodb_table" "transcriptions_table" {
  name         = "Transcriptions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "JobName"

  attribute {
    name = "JobName"
    type = "S"
  }
}

# S3 Notification for completed transcription
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.audio_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_transcription_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "transcription_"
    filter_suffix       = ".json"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_to_invoke_process_transcription_lambda
  ]
}

# Permission for S3 to trigger process lambda
resource "aws_lambda_permission" "allow_s3_to_invoke_process_transcription_lambda" {
  statement_id  = "AllowS3InvokeProcessTranscription"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_transcription_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.audio_bucket.arn
}
