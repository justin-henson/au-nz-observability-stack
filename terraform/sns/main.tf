terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "au-nz-observability-stack"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "https://github.com/justin-henson/au-nz-observability-stack"
    }
  }
}

locals {
  common_tags = merge(
    var.tags,
    {
      Module = "sns-notifications"
    }
  )
}

# Critical alarms topic - for P1/P2 incidents requiring immediate attention
resource "aws_sns_topic" "critical_alarms" {
  name              = "${var.environment}-critical-alarms"
  display_name      = "Critical Alarms - ${var.environment}"
  kms_master_key_id = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-critical-alarms"
      Severity = "critical"
      Purpose  = "pagerduty-integration"
    }
  )
}

# Warning alarms topic - for P3 incidents requiring attention within 2 hours
resource "aws_sns_topic" "warning_alarms" {
  name              = "${var.environment}-warning-alarms"
  display_name      = "Warning Alarms - ${var.environment}"
  kms_master_key_id = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-warning-alarms"
      Severity = "warning"
      Purpose  = "slack-integration"
    }
  )
}

# Info alarms topic - for P4 informational alerts
resource "aws_sns_topic" "info_alarms" {
  name              = "${var.environment}-info-alarms"
  display_name      = "Info Alarms - ${var.environment}"
  kms_master_key_id = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-info-alarms"
      Severity = "info"
      Purpose  = "email-digest"
    }
  )
}

# Email subscriptions for critical alarms
resource "aws_sns_topic_subscription" "critical_email" {
  for_each = toset(var.critical_email_endpoints)

  topic_arn = aws_sns_topic.critical_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# Email subscriptions for warning alarms
resource "aws_sns_topic_subscription" "warning_email" {
  for_each = toset(var.warning_email_endpoints)

  topic_arn = aws_sns_topic.warning_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# Email subscriptions for info alarms
resource "aws_sns_topic_subscription" "info_email" {
  for_each = toset(var.info_email_endpoints)

  topic_arn = aws_sns_topic.info_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# HTTPS subscription for PagerDuty integration (critical alarms)
resource "aws_sns_topic_subscription" "pagerduty" {
  count = var.pagerduty_endpoint != "" ? 1 : 0

  topic_arn = aws_sns_topic.critical_alarms.arn
  protocol  = "https"
  endpoint  = var.pagerduty_endpoint
}

# HTTPS subscription for Slack integration (warning alarms)
resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  topic_arn = aws_sns_topic.warning_alarms.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# SNS topic policy to allow CloudWatch to publish
resource "aws_sns_topic_policy" "critical_alarms" {
  arn = aws_sns_topic.critical_alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.critical_alarms.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "warning_alarms" {
  arn = aws_sns_topic.warning_alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.warning_alarms.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "info_alarms" {
  arn = aws_sns_topic.info_alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.info_alarms.arn
      }
    ]
  })
}
