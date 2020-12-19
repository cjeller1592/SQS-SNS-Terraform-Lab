#!/bin/bash

terraform init

echo "Creating the lab ..."

terraform apply --auto-approve

echo "Publishing message to the SNS topic ..."

aws sns publish --topic-arn $(terraform output sns_arn) --message file://message.txt

echo "Finding the SNS message in the SQS queue ..."

aws sqs receive-message --queue-url $(terraform output queue_url)