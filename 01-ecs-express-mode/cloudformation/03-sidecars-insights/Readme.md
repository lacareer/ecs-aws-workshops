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

<!-- Stress testing -->
We use the package 'hey' for stress testing: https://github.com/rakyll/hey
***Hey Installation***
    $ curl --output hey  https://storage.googleapis.com/hey-releases/hey_linux_amd64 [downloads package into a file I called hey in my user/home directory]

    $ chmod u+x hey [makes it executable]

    $ sudo mv hey /usr/local/bin/hey [Move the downloaded binary to where binary are and run from]

    $ hey https://google.com [test hey with default to confirm it works]

        Summary:
        Total:        0.8528 secs
        Slowest:      0.4321 secs
        Fastest:      0.1118 secs
        Average:      0.1844 secs
        Requests/sec: 234.5209
        

        Response time histogram:
        0.112 [1]     |
        0.144 [122]   |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
        0.176 [24]    |■■■■■■■■
        0.208 [2]     |■
        0.240 [1]     |
        0.272 [2]     |■
        0.304 [4]     |■
        0.336 [13]    |■■■■
        0.368 [27]    |■■■■■■■■■
        0.400 [3]     |■
        0.432 [1]     |


        Latency distribution:
        10%% in 0.1200 secs
        25%% in 0.1254 secs
        50%% in 0.1365 secs
        75%% in 0.2606 secs
        90%% in 0.3450 secs
        95%% in 0.3579 secs
        99%% in 0.3691 secs

        Details (average, fastest, slowest):
        DNS+dialup:   0.0176 secs, 0.0000 secs, 0.0948 secs
        DNS-lookup:   0.0041 secs, 0.0000 secs, 0.0459 secs
        req write:    0.0026 secs, 0.0000 secs, 0.0364 secs
        resp wait:    0.0816 secs, 0.0656 secs, 0.1966 secs
        resp read:    0.0137 secs, 0.0011 secs, 0.0509 secs

        Status code distribution:
        [200] 200 responses


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

 <!-- You can also verify side car from the CLI: -->

    $ TASK_ARN=$(aws ecs list-tasks --cluster retail-store-express --service-name ui-express --query 'taskArns[0]' --output text)

    $ aws ecs describe-tasks --cluster retail-store-express --tasks $TASK_ARN   --query 'tasks[0].{taskDefinition:taskDefinitionArn,containers:containers[*].{name:name,status:lastStatus}}' --output table

    -------------------------------------------------------------------------------------------------
    |                                         DescribeTasks                                         |
    +----------------+------------------------------------------------------------------------------+
    |  taskDefinition|  arn:aws:ecs:us-east-1:471112967827:task-definition/retail-store-express:1   |
    +----------------+------------------------------------------------------------------------------+
    ||                                         containers                                          ||
    |+---------------------------------------------------+-----------------------------------------+|
    ||                       name                        |                 status                  ||
    |+---------------------------------------------------+-----------------------------------------+|
    ||  Main                                             |  RUNNING                                ||
    ||  log-router                                       |  RUNNING                                ||
    |+---------------------------------------------------+-----------------------------------------+|




