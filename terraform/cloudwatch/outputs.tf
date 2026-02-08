output "dashboard_urls" {
  description = "CloudWatch Dashboard URLs"
  value = {
    infrastructure = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.infrastructure.dashboard_name}"
  }
}

output "alarm_names" {
  description = "Names of created CloudWatch alarms"
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu_warning : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ec2_cpu_critical : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ec2_status_check : alarm.alarm_name],
    var.alb_arn_suffix != "" ? [
      aws_cloudwatch_metric_alarm.alb_response_time[0].alarm_name,
      aws_cloudwatch_metric_alarm.alb_5xx_count[0].alarm_name,
      aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_name,
      aws_cloudwatch_metric_alarm.alb_rejected_connections[0].alarm_name
    ] : [],
    [for alarm in aws_cloudwatch_metric_alarm.rds_cpu : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.rds_memory : alarm.alarm_name]
  )
}

output "log_group_names" {
  description = "Names of created log groups"
  value = {
    application    = aws_cloudwatch_log_group.application.name
    infrastructure = aws_cloudwatch_log_group.infrastructure.name
    security       = aws_cloudwatch_log_group.security.name
  }
}

output "composite_alarm_names" {
  description = "Names of created composite alarms"
  value = [
    aws_cloudwatch_composite_alarm.service_degradation[0].alarm_name,
    aws_cloudwatch_composite_alarm.capacity_exhaustion[0].alarm_name
  ]
}
