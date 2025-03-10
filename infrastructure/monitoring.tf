# Add CloudWatch metric alarm for port 8000 availability
resource "aws_cloudwatch_metric_alarm" "flask_health" {
  count             = var.skip_data_sources ? 0 : 1
  alarm_name          = "flask-app-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors Flask application health"
  
  # Use data sources to get ARNs from existing resources
  dimensions = {
    TargetGroup  = "k8s-default-webappne-68b86f9f40"  # Just the suffix, not the full ARN
    LoadBalancer = "app/k8s-default-webappne-338b082b37/ecdeb8cb86aa34c7"  # ALB name from the console
  }
}

# Install Prometheus for monitoring
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "51.2.0"
  namespace        = "prometheus"
  create_namespace = true

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.serviceMonitor.selfMonitor"
    value = "true"
  }

  timeout = 600  # Increase timeout to 10 minutes

  depends_on = [
    aws_eks_node_group.main,
    helm_release.aws_load_balancer_controller
  ]
}