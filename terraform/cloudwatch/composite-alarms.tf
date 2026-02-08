# Composite Alarms combine multiple alarm states to detect complex failure scenarios
# and reduce alert noise by grouping related symptoms into single actionable alerts

resource "aws_cloudwatch_composite_alarm" "service_degradation" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name        = "${var.environment}-service-degradation"
  alarm_description = "Service is degraded: both high 5xx errors AND slow response times detected. Users experiencing errors and latency. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md"
  actions_enabled   = true
  alarm_actions     = local.alarm_actions
  ok_actions        = local.ok_actions

  alarm_rule = join(" AND ", [
    "ALARM(${aws_cloudwatch_metric_alarm.alb_5xx_count[0].alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name})"
  ])

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-service-degradation"
      Severity = "critical"
      Type     = "composite"
    }
  )
}

resource "aws_cloudwatch_composite_alarm" "capacity_exhaustion" {
  count = length(var.ec2_instance_ids) > 0 ? 1 : 0

  alarm_name        = "${var.environment}-capacity-exhaustion"
  alarm_description = "Multiple instances showing capacity exhaustion: CPU AND memory pressure detected. Scale out required. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  actions_enabled   = true
  alarm_actions     = local.alarm_actions
  ok_actions        = local.ok_actions

  alarm_rule = join(" OR ", [
    for instance_id in var.ec2_instance_ids :
    "(ALARM(${aws_cloudwatch_metric_alarm.ec2_cpu_critical[instance_id].alarm_name}))"
  ])

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-capacity-exhaustion"
      Severity = "critical"
      Type     = "composite"
    }
  )
}
