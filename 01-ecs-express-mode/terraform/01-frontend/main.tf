locals {
  ecs_cluster_name                  = var.cluster_name
  ecs_service_name                  = var.service_name
  ecs_container_image               = var.container_image
  ecs_container_port                = var.container_port
  ecs_health_check_path             = var.health_check_path
  ecs_cpu                           = var.cpu
  ecs_memory                        = var.memory
  ecs_ui_theme                      = var.ui_theme
  ecs_public_subnets                = var.public_subnet_ids
  ecs_primary_container_environment = var.environment
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecs_trust_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_infra_trust_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# ecs express mode infrastructure role
resource "aws_iam_role" "ecs_expressInfra_role" {
  name               = "ecsExpressInfrastructureRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_infra_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_role_ssm" {
  role       = aws_iam_role.ecs_expressInfra_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

# ecs express mode task execution role
resource "aws_iam_role" "retail_store_ecs_task_execution_role" {
  name               = "retailStoreEcsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "retail_store_ecs_task_execution_role_attachment" {
  role       = aws_iam_role.retail_store_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ecs express mode task role 
data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/express/*",
    ]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecsExpressTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
}

resource "aws_iam_role_policy" "ecs_task_role_policy_attachment" {
  role   = aws_iam_role.ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_task_role_policy.json
}


# ecs cluster
resource "aws_ecs_cluster" "ecs_express_mode_cluster" {
  name = local.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ecs express mode service
resource "aws_ecs_express_gateway_service" "express_mode_service" {
  service_name            = local.ecs_service_name
  cluster                 = aws_ecs_cluster.ecs_express_mode_cluster.arn
  execution_role_arn      = aws_iam_role.retail_store_ecs_task_execution_role.arn
  infrastructure_role_arn = aws_iam_role.ecs_expressInfra_role.arn
  cpu                     = local.ecs_cpu
  memory                  = local.ecs_memory

  primary_container {
    image          = local.ecs_container_image
    container_port = local.ecs_container_port
    ##single env
    # environment {
    #   name  = "RETAIL_UI_THEME"
    #   value = local.ecs_ui_theme
    # }

    ##multiple environment variables
    ##note that the 2nd env, RETAIL_UI_BANNER_TEXT = "Welcome", was add just for demonstration purposes and not part of exercise
    # environment {
    #   name  = "RETAIL_UI_THEME"
    #   value = local.ecs_ui_theme
    # }
    # environment {
    #   name  = "RETAIL_UI_BANNER_TEXT"
    #   value = "Welcome"
    # }    


    ## dynamic sample code for multiple environment variables
    ## exapnd to the above multiple env scenerio above if local.ecs_primary_container_environment hold more than one key/value pair
    dynamic "environment" {
      for_each = local.ecs_primary_container_environment
      content {
        name  = environment.key
        value = environment.value
      }
    }
  }

  network_configuration {
    subnets = local.ecs_public_subnets
  }

  depends_on = [aws_iam_role.ecs_expressInfra_role, aws_iam_role.retail_store_ecs_task_execution_role]
}

