# This file is part of the AWS Lambda and LocalStack project.

# Provider configuration
# This Terraform configuration file sets up a LocalStack environment with AWS services
provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true   # Skip credentials validation for LocalStack
  skip_metadata_api_check     = true   # Skip metadata API check for LocalStack
  access_key                  = "test" # Use dummy access key for LocalStack
  secret_key                  = "test" # Use dummy secret key for LocalStack

  # Use LocalStack endpoints for AWS services
  endpoints {
    s3      = "https://s3.localhost.localstack.cloud:4566"
    sqs     = "https://localhost.localstack.cloud:4566"
    sns     = "https://localhost.localstack.cloud:4566"
    lambda  = "https://localhost.localstack.cloud:4566"
    kinesis = "https://localhost.localstack.cloud:4566"
    iam     = "https://localhost.localstack.cloud:4566"
  }
}

# Create AWS resources

# Create an S3 bucket
# resource "aws_s3_bucket" "datastorage" {
#   bucket = "datastorage"
# }

# Create kinesis stream
resource "aws_kinesis_stream" "datastream" {
  name             = "datastream"
  shard_count      = 1
  retention_period = 24
}

# Create an SNS topic
resource "aws_sns_topic" "notifications" {
  name = "notifications"
}

# Create an SQS queue
resource "aws_sqs_queue" "sqs_for_sns" {
  name = "sqs_for_sns"
}

# Associate the SQS queue with the SNS topic
resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn              = aws_sns_topic.notifications.arn
  protocol               = "sqs"
  endpoint               = aws_sqs_queue.sqs_for_sns.arn
  endpoint_auto_confirms = true
}

# Create an IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Permission policy for role from policy.json
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = file("${path.module}/policy.json")
}

# Create a Lambda function
resource "aws_lambda_function" "datamanipulation" {
  function_name    = "datamanipulation"
  filename         = "${path.module}/../lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")
  handler          = "datamanipulation.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role.arn # IAM role for Lambda function

  # Environment variables for Lambda function
  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }
}

# Event source mapping for Kinesis stream to Lambda function
resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.datastream.arn
  function_name     = aws_lambda_function.datamanipulation.arn
  starting_position = "LATEST"
  batch_size        = 1
}
