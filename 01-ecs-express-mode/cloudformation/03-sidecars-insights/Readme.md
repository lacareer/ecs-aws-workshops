THIS IS A CONTINUATION OF THE PREVIOUS MODULE

<!-- What you'll do -->
Enable Container Insights: activate enhanced observability to get per-service CPU, memory, and network metrics with a service topology map.

Add a FireLens sidecar: modify the task definition to route logs through Fluent Bit, then verify Express Mode preserves the sidecar across subsequent updates.

<!-- Key concepts -->
- Shared responsibility model: Express Mode APIs manage resources with coordinated updates. 
  Standard AWS APIs give you direct control over individual resources. Both operate on the same infrastructure in your account.

- Sidecar containers: additional containers in the same task that extend functionality (logging, monitoring, proxies) without modifying the application code.

- FireLens: an ECS-native log routing solution based on Fluent Bit. It allows you to route container logs to multiple destinations (CloudWatch, S3, Elasticsearch, Datadog, Splunk).

<!-- Deployment -->
Deploy the resource in this order:

1. Deploy the VPC in pre-req/one-vpc.yaml

2. Wait for item 1 deploment to complete successfully

3. Deploy 01-ecs-express-mode/cloudformation/03-sidecars-cw-insights/express-mode.yaml

4. Wait for item 3 deploment to complete successfully


*** LABS ***
<!-- Container Insights -->
Before adding sidecars and customizing the logging pipeline, the ops team wants full visibility into container-level metrics: "We need CPU, memory, and network stats per container, not just per service."

CloudWatch Container Insights  with enhanced observability delivers per-container CPU, memory, and network metrics, not just aggregated service-level data.

<!-- Container Insights is already enabled -->
Good news: our cluster was created with Container Insights in enhanced mode already enabled. You can verify this by checking the cluster settings:

    $ aws ecs describe-clusters --clusters <CLUSTER_NAME> --include SETTINGS --query 'clusters[*].settings'

<!-- How to enable Container Insights manually -->
If you ever need to enable Container Insights on a cluster that doesn't have it, run:

    $ aws ecs update-cluster-settings --cluster default --settings name=containerInsights,value=enhanced

Enhanced Container Insights metrics are only available for new tasks launched after enabling enhanced mode. 
You would need to restart your services to get container-level visibility:

    $ for service in ui-express catalog-express cart-express orders-express checkout-express; do
        echo "Restarting ${service}..."
        aws ecs update-service --cluster default --service $service --force-new-deployment --query service.serviceName --output text
      done    

<!-- Add FireLens Sidecar -->
So far, Express Mode has managed all the underlying ECS resources for you: task definitions, load balancers, security groups, and log configuration. 
But Express Mode services are built on standard ECS primitives, which means you can modify the underlying resources when needed.

In this lab, you'll go beyond what Express Mode configures out of the box by directly modifying the task definition of a running service. 
Specifically, you'll add a sidecar container (FireLens/Fluent Bit) alongside the application container and reconfigure the logging pipeline. 
This demonstrates that Express Mode doesn't lock you in, you always have full access to the underlying ECS building blocks.

<!-- What is FireLens? -->
FireLens is an ECS-native log routing solution based on Fluent Bit . 
It allows you to route container logs to multiple destinations (CloudWatch, S3, Elasticsearch, Datadog, Splunk) without modifying your application code.

Why add it? Express Mode already sends logs to CloudWatch using the awslogs driver. 
FireLens gives you more control: you can transform logs, filter them, or send them to additional destinations for compliance or centralized observability.

<!-- Side Car Addition -->

*** CLOUDFORMATION ***
To add the side car, a custom Task Definition has been added and some of the properties therein commented out in the UiExpressService as shown below:

    # ---------------------------------------------------------------------
    UiExpressService:
        Type: AWS::ECS::ExpressGatewayService
        Properties:
        ServiceName: !Ref UiServiceName
        Cluster: !Ref EcsCluster
        HealthCheckPath: !Ref UiHealthCheckPath
        InfrastructureRoleArn: !GetAtt EcsExpressInfrastructureRole.Arn
        ## Comment: The primary container configuration is commented out because the task definition is being referenced directly via TaskDefinitionArn.
        ## A demonstration of how to configure the primary container directly within the ECS and to add a side car container for logging.
        # Memory: !Ref Mem
        # Cpu: !Ref Cpu
        # ExecutionRoleArn: !GetAtt RetailStoreEcsTaskExecutionRole.Arn
        # TaskRoleArn: !GetAtt EcsExpressTaskRole.Arn
        # PrimaryContainer:
        #   Image: !Ref UiContainerImage
        #   ContainerPort: !Ref UiContainerPort
        #   Environment:
        #     - Name: RETAIL_UI_THEME
        #       Value: !Ref UiTheme        
        #     - Name: RETAIL_UI_ENDPOINTS_CATALOG
        #       Value: !Sub "https://${CatalogExpressService.Endpoint}"        
        #     - Name: RETAIL_UI_ENDPOINTS_CARTS
        #       Value: !Sub "https://${CartExpressService.Endpoint}"        
        #     - Name: RETAIL_UI_ENDPOINTS_CHECKOUT
        #       Value: !Sub "https://${CheckoutExpressService.Endpoint}"        
        #     - Name: RETAIL_UI_ENDPOINTS_ORDERS
        #       Value: !Sub "https://${OrdersExpressService.Endpoint}"   
        TaskDefinitionArn: !GetAtt UiTaskDefinition.TaskDefinitionArn
        NetworkConfiguration:
            Subnets:
            - !ImportValue VpcAPublicSubnetAZ1
            - !ImportValue VpcAPublicSubnetAZ2
        Tags:
            - Key: Name
            Value: !Ref UiServiceName

*** CLI ***

What needs to change in the task definition
To enable FireLens, you need two modifications:

Add a log router container: a Fluent Bit sidecar with firelensConfiguration
Change the app's log driver: from awslogs to awsfirelens, so logs flow through Fluent Bit
Here's what the log router container looks like:

    {
        "name": "log-router",
        "image": "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable",
        "essential": true,
        "memoryReservation": 50,
        "firelensConfiguration": { "type": "fluentbit" },
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
            "awslogs-group": "/ecs/express-mode/firelens-internal",
            "awslogs-region": "<region>",
            "awslogs-stream-prefix": "firelens",
            "awslogs-create-group": "true"
            }
        }
    }

And the app container's log configuration changes to:

    "logConfiguration": {
        "logDriver": "awsfirelens",
        "options": {
            "Name": "cloudwatch",
            "region": "<region>",
            "log_group_name": "/ecs/express-mode/firelens",
            "log_stream_prefix": "ui-",
            "auto_create_group": "true"
        }
    }

Register the updated task definition

    $ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-ui-firelens-taskdef.json \
    --query taskDefinition.taskDefinitionArn --output text

And finally deploy the new version of the service

    $ aws ecs update-service \
    --cluster default \
    --service ui-express \
    --task-definition default-ui-express \
    --force-new-deployment \
    --query service.serviceName --output text

You can monitor the deployment progress:

    $ aws ecs describe-services \
    --cluster default \
    --services ui-express \
    --query 'services[0].deployments[*].{
        status:status,
        taskDefinition:taskDefinition,
        runningCount:runningCount,
        desiredCount:desiredCount,
        rolloutState:rolloutState
    }' \
    --output table

Run the following command to wait unitl the deployment is completed

    $ echo_y "Waiting for ui-express service to stabilize with the new task definition..."

    $ aws ecs wait services-stable --cluster default --services ui-express

    $ echo_c "ui-express service is stable!"  

 <!-- You can also verify from the CLI: -->

    TASK_ARN=$(aws ecs list-tasks --cluster default --service-name ui-express --query 'taskArns[0]' --output text)

    $ aws ecs describe-tasks --cluster default --tasks $TASK_ARN \
      --query 'tasks[0].{taskDefinition:taskDefinitionArn,containers:containers[*].{name:name,status:lastStatus}}' --output table

You should see output similar to:

    ------------------------------------------------------------------------------------------
    |                                      DescribeTasks                                      |
    +----------------+------------------------------------------------------------------------+
    |  taskDefinition|  arn:aws:ecs:us-east-1:XXXXXXXXX:task-definition/xxx-ui-express:vv  |
    +----------------+------------------------------------------------------------------------+
    ||                                      containers                                       ||
    |+-------------------------------------------+-------------------------------------------+|
    ||                   name                     |                  status                  ||
    |+-------------------------------------------+-------------------------------------------+|
    ||  aws-guardduty-agent-xxxxx                |  RUNNING                                  ||
    ||  log-router                               |  RUNNING                                  ||
    ||  Main                                     |  RUNNING                                  ||
    |+-------------------------------------------+-------------------------------------------+|  




