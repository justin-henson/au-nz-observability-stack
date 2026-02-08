# CloudWatch monitoring configuration for AWS infrastructure
# This module creates dashboards, alarms, log groups, and metric filters
# for comprehensive observability across EC2, ALB, EKS, and RDS services

locals {
  common_tags = merge(
    var.tags,
    {
      Module = "cloudwatch-monitoring"
    }
  )

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]
}
