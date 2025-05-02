# This Lambda function processes records from a Kinesis stream, modifies the data, and stores it in S3.
# It also handles errors by sending notifications to an SNS topic.
# The function is triggered by Kinesis events and uses the AWS SDK for Python (Boto3) to interact with S3 and SNS.
# The function expects the Kinesis event to contain records with a specific structure and handles exceptions gracefully.

# Import necessary libraries
import json
import boto3 # AWS SDK for Python
import os
import base64 # For decoding base64-encoded data

s3 = boto3.client('s3') # S3 client to interact with Amazon S3
sns = boto3.client('sns') # SNS client to interact with Amazon Simple Notification Service

bucket_name = 'datastorage' # S3 bucket name where the processed data will be stored
topic_arn = os.environ['TOPIC_ARN'] # SNS topic ARN for error notifications

# Lambda function handler
# This function is triggered by Kinesis events
def lambda_handler(event, context):
    for record in event['Records']:
        try:
            # Data processing logic
            # Decode the base64-encoded data from the Kinesis record
            # The data is expected to be in JSON format
            data = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            payload = json.loads(data)
            # Modify the payload add a test key
            payload['test'] = True

            # Generate a unique file name using the event ID
            # The event ID is extracted from the Kinesis record
            # The file name is used to store the processed data in S3
            # The file is stored in JSON format
            event_id = record['eventID']
            file_name = f"{event_id}.json"

            # Store the processed data in S3
            s3.put_object(
                Bucket=bucket_name,
                Key=file_name,
                Body=json.dumps(payload)
            )
        # Handle exceptions
        except Exception as e:
            error_message = {
                "error": str(e),
                "record": record
            }
            # Send error notification to SNS
            # The error message contains the exception details and the Kinesis record that caused the error
            # This allows for easier debugging and monitoring of the Lambda function
            sns.publish(
                TopicArn=topic_arn,
                Message=json.dumps(error_message)
            )
    # Return a success message
    return {"status": "Terminated"}