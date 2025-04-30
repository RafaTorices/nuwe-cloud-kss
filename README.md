# AWS Infrastructure with Terraform

## Description

This script creates an S3 bucket, a Kinesis stream, an SNS topic, an SQS queue, and a Lambda function
The Lambda function is triggered by the Kinesis stream and sends notifications to the SNS topic
The SNS topic is subscribed to the SQS queue
The Lambda function has an IAM role with permissions to access the S3 bucket, Kinesis stream, SNS topic, and SQS queue
The IAM role is created with a policy that allows the Lambda function to perform the necessary actions
The policy is stored in a separate JSON file
The Lambda function code is stored in a zip file in the ../lambda directory
The zip file is created using the zip command in the terminal
The Lambda function code is written in Python and uses the boto3 library to interact with AWS services

## Requirements

- Localstack
- Terraform
- Python 3.8+

## Usage

```bash
cd Infraestructure/lambda
zip lambda.zip datamanipulation.py

cd ../Terraform
terraform init
terraform apply
```
