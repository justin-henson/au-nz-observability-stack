resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.environment}-infrastructure-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "EC2 Network Traffic"
          region = var.aws_region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            ["AWS/EC2", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}
