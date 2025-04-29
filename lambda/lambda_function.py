import json
import boto3
import os
import base64
import uuid
from datetime import datetime

# Initialize AWS clients
s3_client = boto3.client("s3")
transcribe_client = boto3.client("transcribe")
dynamodb = boto3.resource("dynamodb")

# Environment variables (set in Terraform)
BUCKET_NAME = os.environ["BUCKET_NAME"]
DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "Transcriptions")

def lambda_handler(event, context):
    try:
        print("Event received:", json.dumps(event)[:500])  # Debug small part of event

        is_base64_encoded = event.get("isBase64Encoded", False)
        body = event["body"]

        # Decode if necessary
        if is_base64_encoded:
            file_content = base64.b64decode(body)
        else:
            file_content = body.encode("utf-8")

        # Generate unique filename
        audio_filename = f"audio_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.mp3"
        
        # Upload audio file to S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=audio_filename,
            Body=file_content,
            ContentType="audio/mpeg"  # Correct MIME type for MP3
        )

        # Start a Transcribe job
        job_name = f"transcription_{uuid.uuid4()}"
        s3_uri = f"s3://{BUCKET_NAME}/{audio_filename}"

        transcribe_client.start_transcription_job(
            TranscriptionJobName=job_name,
            Media={"MediaFileUri": s3_uri},
            MediaFormat="mp3",                # IMPORTANT: set to mp3
            LanguageCode="en-US",
            OutputBucketName=BUCKET_NAME
        )

        # Insert initial status into DynamoDB
        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        table.put_item(Item={
            "JobName": job_name,
            "Status": "IN_PROGRESS",
            "AudioFile": audio_filename,
            "CreatedAt": datetime.utcnow().isoformat()
        })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "File uploaded and transcription started",
                "job_name": job_name
            })
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
