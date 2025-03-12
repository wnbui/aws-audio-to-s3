import json
import boto3
import os
from datetime import datetime

s3 = boto3.client("s3")
BUCKET_NAME = os.environ["BUCKET_NAME"]

def lambda_handler(event, context):
    file_content = event["body"]
    filename = f"audio_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.wav"

    try:
        s3.put_object(Bucket=BUCKET_NAME, Key=filename, Body=file_content, ContentType="audio/wav")
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "File uploaded", "file_url": f"s3://{BUCKET_NAME}/{filename}"}),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Upload failed", "error": str(e)}),
        }
