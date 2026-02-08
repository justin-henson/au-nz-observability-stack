# Log Metric Filters extract custom metrics from log data,
# enabling alerting on application-specific events and error patterns

# Filter for ERROR level log entries
resource "aws_cloudwatch_log_metric_filter" "application_errors" {
  name           = "${var.environment}-application-errors"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level = ERROR*, msg]"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "CustomMetrics/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

# Alarm on application error rate
resource "aws_cloudwatch_metric_alarm" "application_error_rate" {
  alarm_name          = "${var.environment}-application-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApplicationErrorCount"
  namespace           = "CustomMetrics/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "Application error count exceeds 50 in 5 minutes. Check application logs for root cause. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    LogType     = "application"
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-application-error-rate"
      Severity = "warning"
      Source   = "log-metric-filter"
    }
  )
}

# Filter for HTTP 5xx responses
resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${var.environment}-http-5xx-responses"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level, msg, status_code = 5*, ...]"

  metric_transformation {
    name      = "HTTP5xxCount"
    namespace = "CustomMetrics/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

# Filter for slow requests (latency threshold)
resource "aws_cloudwatch_log_metric_filter" "slow_requests" {
  name           = "${var.environment}-slow-requests"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level, msg = \"*slow request*\", latency > 2000, ...]"

  metric_transformation {
    name      = "SlowRequestCount"
    namespace = "CustomMetrics/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

# Alarm on slow request rate
resource "aws_cloudwatch_metric_alarm" "slow_request_rate" {
  alarm_name          = "${var.environment}-slow-request-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "SlowRequestCount"
  namespace           = "CustomMetrics/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "Slow request count exceeds 20 in 5 minutes. Application performance degraded. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    Threshold   = "2000ms"
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-slow-request-rate"
      Severity = "warning"
      Source   = "log-metric-filter"
    }
  )
}

# Filter for authentication failures
resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "${var.environment}-auth-failures"
  log_group_name = aws_cloudwatch_log_group.security.name
  pattern        = "[time, request_id, level, event = \"authentication_failed\", ...]"

  metric_transformation {
    name      = "AuthenticationFailureCount"
    namespace = "CustomMetrics/${var.environment}"
    value     = "1"
    unit      = "Count"
  }
}

# Alarm on authentication failure spike (potential security incident)
resource "aws_cloudwatch_metric_alarm" "auth_failure_spike" {
  alarm_name          = "${var.environment}-auth-failure-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AuthenticationFailureCount"
  namespace           = "CustomMetrics/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Authentication failure count exceeds 100 in 5 minutes. Potential brute force attack or misconfiguration. Review security logs immediately."
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
    EventType   = "auth_failure"
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-auth-failure-spike"
      Severity = "critical"
      Source   = "log-metric-filter"
      Category = "security"
    }
  )
}
