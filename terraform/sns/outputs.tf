output "critical_alarms_topic_arn" {
  description = "ARN of the critical alarms SNS topic"
  value       = aws_sns_topic.critical_alarms.arn
}

output "warning_alarms_topic_arn" {
  description = "ARN of the warning alarms SNS topic"
  value       = aws_sns_topic.warning_alarms.arn
}

output "info_alarms_topic_arn" {
  description = "ARN of the info alarms SNS topic"
  value       = aws_sns_topic.info_alarms.arn
}

output "critical_alarms_topic_name" {
  description = "Name of the critical alarms SNS topic"
  value       = aws_sns_topic.critical_alarms.name
}

output "warning_alarms_topic_name" {
  description = "Name of the warning alarms SNS topic"
  value       = aws_sns_topic.warning_alarms.name
}

output "info_alarms_topic_name" {
  description = "Name of the info alarms SNS topic"
  value       = aws_sns_topic.info_alarms.name
}
