See docs  here: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ecs-service.html


<!-- Spot instances -->
With Fargate Spot, you can run Amazon ECS tasks at a rate that's discounted compared to the Fargate price. For more information, check the AWS documentation . Fargate Spot runs tasks on spare compute capacity. When AWS needs the capacity back, your tasks are interrupted with a two-minute warning.

Fargate Spot is only recommended for applications that can handle interruption, such as stateless, fault-tolerant, and flexible applications. Because Spot is spare Amazon EC2 capacity, which can change over time, we recommend that you use Spot capacity for interruption-tolerant workloads. More specifically, Spot capacity is suitable for workloads that can tolerate periods where the required capacity isn't available. Critical workloads shouldn't solely rely on Spot but should also have regular on-demand Fargate tasks.

We are setting this up on the ui service only for demonstration purposes.

<!-- Capacity providers -->
Amazon ECS capacity providers manage the scaling of the infrastructure in your clusters. Each cluster can have one or more capacity providers and an optional capacity provider strategy. The capacity provider strategy determines how the tasks are spread across the cluster's capacity providers. When you run a standalone task or create a service, you either use the cluster's default capacity provider strategy or a capacity provider strategy that overrides the default one.

The command above with default-capacity-provider-strategy flag means if no capacity provider or launch type is specified during creating a service or running a task, then this default capacity provider strategy for ECS cluster is going to be used.

- base value designates how many tasks, at a minimum, to run on the specified capacity provider. Only one capacity provider in a capacity provider strategy can have a base defined.

- weight value designates the relative percentage of the total number of launched tasks that should use the specified capacity provider. For example, if you have a strategy that contains two capacity providers, and both have a weight of 1, then when the base is satisfied, the tasks will be split evenly across the two capacity providers.

In our scenario:

- Regular FARGATE gets a base of 1, in order to be sure at least one task will use one on-demand
- FARGATE_SPOT gets a higher weight (1:0), meaning more tasks will prefer Spot when possible

<!-- How to handle termination -->
Typically, your container will receive signal SIGTERM  (15, software termination signal). Most frameworks, applications and web servers receive this signal and gracefully shutdown.

If the container is not stopped before the stopTimeout period, ECS will send signal SIGKILL  (9, non-cacheable, non-ignorable kill) and may result in data loss or corruption. Note that stopTimeout value cannot be longer than 120 seconds .


# commands 

    $ aws ecs describe-clusters --clusters retail-store-ecs-cluster

    $ aws ecs put-cluster-capacity-providers \
        --cluster retail-store-ecs-cluster \
        --capacity-providers FARGATE FARGATE_SPOT \
        --default-capacity-provider-strategy \
            capacityProvider=FARGATE,weight=0,base=1 \
            capacityProvider=FARGATE_SPOT,weight=1,base=0

    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service ui \
        --capacity-provider-strategy \
            capacityProvider=FARGATE,weight=0,base=1 \
            capacityProvider=FARGATE_SPOT,weight=1,base=0 \
        --force-new-deployment


    $ tasks_arns=$(aws ecs list-tasks --cluster retail-store-ecs-cluster --service-name ui --query 'taskArns' --output text)

    $ echo ${tasks_arns} | xargs aws ecs describe-tasks --cluster retail-store-ecs-cluster \
        --tasks \
        --query 'tasks[].{lastStatus: lastStatus, startedAt: startedAt, status: healthStatus, capacityProvider: capacityProviderName}' \
        --output table

    $ aws ecs update-service \
        --cluster retail-store-ecs-cluster \
        --service ui \
        --capacity-provider-strategy \
            capacityProvider=FARGATE,weight=1 \
        --force-new-deployment        

    $ aws ecs put-cluster-capacity-providers \
            --cluster retail-store-ecs-cluster \
            --capacity-providers FARGATE \
            --default-capacity-provider-strategy        