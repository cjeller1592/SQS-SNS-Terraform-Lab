provider "aws" {
  region = "us-east-2"
}

# Creating the SNS topic

resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
  delivery_policy = <<EOF
  {
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

# Creating the SQS queue

resource "aws_sqs_queue" "user_updates_queue" {
  name = "user-updates-queue"
}

# Creating the queue policy for SQS to send messages to SNS
resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.user_updates_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.user_updates_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.user_updates.arn}"
        }
      }
    }
  ]
}
POLICY
}

# Creating the topic subscription which uses our created SQS' ARN

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.user_updates_queue.arn
}

output "queue_url" {
    value   = aws_sqs_queue.user_updates_queue.id
}

output "sns_arn" {
    value   = aws_sns_topic.user_updates.arn
}