# EC2 Instance Alarms

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_warning" {
  for_each = toset(var.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-${each.key}-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeds 80% for 5 minutes. Investigate workload and consider scaling. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = each.key
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-ec2-${each.key}-cpu-warning"
      Severity = "warning"
      Resource = each.key
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_critical" {
  for_each = toset(var.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-${each.key}-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 180
  statistic           = "Average"
  threshold           = 95
  alarm_description   = "CPU utilization exceeds 95% for 3 minutes. Immediate action required. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = each.key
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-ec2-${each.key}-cpu-critical"
      Severity = "critical"
      Resource = each.key
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = toset(var.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-${each.key}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed for 2 consecutive periods. Instance may be unreachable. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = each.key
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-ec2-${each.key}-status-check"
      Severity = "critical"
      Resource = each.key
    }
  )
}

# ALB Alarms

resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 2
  alarm_description   = "ALB p99 response time exceeds 2 seconds. User experience degraded. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-alb-response-time"
      Severity = "warning"
      Resource = "alb"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_count" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx errors exceed 10 per minute. Application errors detected. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-alb-5xx-errors"
      Severity = "critical"
      Resource = "alb"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.target_group_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Unhealthy hosts detected in target group for 3 minutes. Traffic routing degraded. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-alb-unhealthy-hosts"
      Severity = "critical"
      Resource = "alb"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-alb-rejected-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RejectedConnectionCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "ALB rejecting connections. Load balancer at capacity or misconfigured. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-alb-rejected-connections"
      Severity = "critical"
      Resource = "alb"
    }
  )
}

# RDS Alarms

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each = toset(var.rds_instance_ids)

  alarm_name          = "${var.environment}-rds-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization exceeds 80% for 5 minutes. Database performance may degrade. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.key
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-rds-${each.key}-cpu"
      Severity = "warning"
      Resource = each.key
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  for_each = toset(var.rds_instance_ids)

  alarm_name          = "${var.environment}-rds-${each.key}-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 268435456
  alarm_description   = "RDS freeable memory below 256MB for 5 minutes. Database may experience OOM errors. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-MEMORY.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.key
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-rds-${each.key}-memory"
      Severity = "critical"
      Resource = each.key
    }
  )
}

# EKS Node Alarms (via Container Insights)

resource "aws_cloudwatch_metric_alarm" "eks_node_not_ready" {
  count = var.eks_cluster_name != "" ? 1 : 0

  alarm_name          = "${var.environment}-eks-node-not-ready"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "EKS cluster has nodes in NotReady state. Workload scheduling may fail. Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/POD-CRASHLOOP.md"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = []

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-eks-node-not-ready"
      Severity = "critical"
      Resource = var.eks_cluster_name
    }
  )
}
