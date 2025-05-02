import json
import os
import boto3

dynamodb   = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]

def lambda_handler(event, context):
    params   = (event.get("queryStringParameters") or {})
    job_name = params.get("job_name")
    if not job_name:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing job_name"})
        }

    table = dynamodb.Table(TABLE_NAME)
    resp  = table.get_item(Key={"JobName": job_name})
    item  = resp.get("Item")
    if not item:
        return {
            "statusCode": 404,
            "body": json.dumps({"status": "NOT_FOUND"})
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "status":        item.get("Status"),
            "transcription": item.get("TranscriptionText")
        })
    }
