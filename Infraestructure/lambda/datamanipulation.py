# This Lambda function processes records from a Kinesis stream, modifies the data, and stores it in S3.
# It also handles errors by sending notifications to an SNS topic.
# The function is triggered by Kinesis events and uses the AWS SDK for Python (Boto3) to interact with S3 and SNS.
# The function expects the Kinesis event to contain records with a specific structure and handles exceptions gracefully.

# Import necessary libraries
import json
import boto3 # AWS SDK for Python
import os

s3 = boto3.client('s3') # S3 client to interact with Amazon S3
sns = boto3.client('sns') # SNS client to interact with Amazon Simple Notification Service

bucket_name = 'datastorage' # S3 bucket name where the processed data will be stored
topic_arn = os.environ['TOPIC_ARN'] # SNS topic ARN for error notifications

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            payload = json.loads(record['kinesis']['data'])
            payload['test'] = True

            event_id = record['eventID']
            file_name = f"{event_id}.json"

            s3.put_object(
                Bucket=bucket_name,
                Key=file_name,
                Body=json.dumps(payload)
            )

        except Exception as e:
            error_message = {
                "error": str(e),
                "record": record
            }
            sns.publish(
                TopicArn=topic_arn,
                Message=json.dumps(error_message)
            )
