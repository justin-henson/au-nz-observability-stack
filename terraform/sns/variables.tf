variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for SNS topics"
  type        = string
  default     = "ap-southeast-2"
}

variable "critical_email_endpoints" {
  description = "Email addresses to receive critical alarm notifications"
  type        = list(string)
  default     = []
}

variable "warning_email_endpoints" {
  description = "Email addresses to receive warning alarm notifications"
  type        = list(string)
  default     = []
}

variable "info_email_endpoints" {
  description = "Email addresses to receive info alarm notifications"
  type        = list(string)
  default     = []
}

variable "pagerduty_endpoint" {
  description = "PagerDuty HTTPS endpoint for critical alarms"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for warning alarms"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
