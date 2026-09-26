cluster_name      = "retail-store-express"
service_name      = "ui-express1"
container_image   = "public.ecr.aws/aws-containers/retail-store-sample-ui:1.5.0"
container_port    = 8080
health_check_path = "/actuator/health"
cpu               = 2048
memory            = 4096
ui_theme          = "orange"
# Public subnet IDs for an existing vpc
public_subnet_ids = ["subnet-0c8a00f23f95aecf6", "subnet-08b4a2cc13277c08d"]
environment = {
  RETAIL_UI_THEME = "orange"
}