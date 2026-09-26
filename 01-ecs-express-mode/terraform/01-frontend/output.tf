##Does not support the application URL endpoint for ECS Express Gateway Service.
output "application_url" {
  value = aws_ecs_express_gateway_service.express_mode_service.ingress_paths
}

output "application_arn" {
  value = aws_ecs_express_gateway_service.express_mode_service.service_arn
}

output "cluster_arn" {
  value = aws_ecs_cluster.ecs_express_mode_cluster.arn
}