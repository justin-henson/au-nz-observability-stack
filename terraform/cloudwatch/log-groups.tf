# Application logs from web services, APIs, and background workers
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-application-logs"
      LogType  = "application"
      Category = "structured"
    }
  )
}

# Infrastructure logs from EC2 instances, system services, and OS-level events
resource "aws_cloudwatch_log_group" "infrastructure" {
  name              = "/aws/infrastructure/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-infrastructure-logs"
      LogType  = "infrastructure"
      Category = "system"
    }
  )
}

# Security logs for audit trails, authentication events, and access logs
resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.environment}"
  retention_in_days = 90
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-security-logs"
      LogType  = "security"
      Category = "audit"
    }
  )
}

# EKS cluster control plane logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.eks_cluster_name != "" ? 1 : 0

  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.environment}-eks-cluster-logs"
      LogType     = "kubernetes"
      Category    = "control-plane"
      ClusterName = var.eks_cluster_name
    }
  )
}

# Container Insights logs for EKS
resource "aws_cloudwatch_log_group" "container_insights" {
  count = var.eks_cluster_name != "" ? 1 : 0

  name              = "/aws/containerinsights/${var.eks_cluster_name}/performance"
  retention_in_days = var.log_retention_days
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.environment}-container-insights"
      LogType     = "kubernetes"
      Category    = "metrics"
      ClusterName = var.eks_cluster_name
    }
  )
}

# Lambda function logs
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = null

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.environment}-lambda-logs"
      LogType  = "serverless"
      Category = "application"
    }
  )
}
