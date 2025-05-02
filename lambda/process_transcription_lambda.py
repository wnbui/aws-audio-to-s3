import json
import boto3
import os

s3_client  = boto3.client("s3")
dynamodb   = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]

def lambda_handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key    = record["s3"]["object"]["key"]

        # Only process transcription JSON files
        if not key.startswith("transcription_") or not key.endswith(".json"):
            continue

        # Fetch and parse Transcribe output
        content = s3_client.get_object(Bucket=bucket, Key=key)["Body"].read()
        jo      = json.loads(content)
        transcripts = jo.get("results", {}).get("transcripts", [])
        text = transcripts[0].get("transcript", "") if transcripts else ""

        # Update DynamoDB item
        job_name = key.replace(".json", "")
        table    = dynamodb.Table(TABLE_NAME)
        table.update_item(
            Key={"JobName": job_name},
            UpdateExpression="SET #st = :s, TranscriptionText = :t",
            ExpressionAttributeNames={"#st": "Status"},
            ExpressionAttributeValues={":s": "COMPLETED", ":t": text}
        )

    return {"statusCode": 200}

