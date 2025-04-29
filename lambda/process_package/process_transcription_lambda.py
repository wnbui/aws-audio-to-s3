import json
import boto3
import os

s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

DYNAMODB_TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "Transcriptions")

def lambda_handler(event, context):
    try:
        record = event["Records"][0]
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = record["s3"]["object"]["key"]

        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        content = response['Body'].read()
        transcription_json = json.loads(content)

        transcription_text = transcription_json['results']['transcripts'][0]['transcript']

        job_name = object_key.split('/')[-1].replace('.json', '')

        table = dynamodb.Table(DYNAMODB_TABLE_NAME)
        table.update_item(
            Key={"JobName": job_name},
            UpdateExpression="SET #s = :s, TranscriptionText = :t",
            ExpressionAttributeNames={"#s": "Status"},
            ExpressionAttributeValues={":s": "COMPLETED", ":t": transcription_text}
        )

        return {"statusCode": 200, "body": "Transcription processed."}

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}
