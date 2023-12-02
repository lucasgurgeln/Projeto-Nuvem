# CloudWatch Alarm para Monitoramento de Escalabilidade
resource "aws_cloudwatch_metric_alarm" "app_high_cpu_usage" {
  alarm_name          = "ElevatedCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70" 
  alarm_description   = "Alarm for high CPU usage in EC2 instances"

  dimensions = {
    ASGName = aws_autoscaling_group.projeto_lucas_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.increase_capacity.arn]
  ok_actions    = [aws_autoscaling_policy.decrease_capacity.arn]
}

resource "aws_cloudwatch_metric_alarm" "app_low_cpu_usage" {
  alarm_name          = "ReducedCPUUsage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "Alarm for low CPU usage in EC2 instances"

  dimensions = {
    ASGName = aws_autoscaling_group.projeto_lucas_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.decrease_capacity.arn]
  ok_actions    = [aws_autoscaling_policy.increase_capacity.arn]
}

# Política de Escalabilidade para Incrementar Capacidade
resource "aws_autoscaling_policy" "increase_capacity" {
  name                   = "increment_capacity"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.projeto_lucas_asg.name
}

# Política de Escalabilidade para Diminuir Capacidade
resource "aws_autoscaling_policy" "decrease_capacity" {
  name                   = "decrement_capacity"
  scaling_adjustment     = -1 
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.projeto_lucas_asg.name
}
