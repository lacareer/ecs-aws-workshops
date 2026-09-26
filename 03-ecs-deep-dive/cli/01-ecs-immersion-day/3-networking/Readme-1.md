<!-- Amazon ECS Network Mode -->
In AWSVPC mode, Amazon ECS creates and manages an Elastic Network Interface (ENI) for each task, and each task receives its own private IP address within the VPC. This configuration provides great flexibility to control communications between tasks and services at a more granular level. The AWSVPC network mode is supported for Amazon ECS tasks hosted on both Amazon EC2 and Fargate.

# When using Amazon ECS on Fargate, the AWSVPC network mode is required.

On AWS console go to a running task and click on it to see the networking configurations - ENI, private IP, VPC cidr etc.

You can access the task information programmatically by executing the following command to get the information of the task running in the ui service:

-$ aws ecs describe-tasks \
 --cluster retail-store-ecs-cluster \
 --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --service ui --query 'taskArns[0]' --output text)

<!-- ECS Service Connect -->
# You must have completed the following chapters as pre-requisites for this lab: Fundamentals

ECS Service Connect is the recommended approach for handling service-to-service communication, offering features such as service discovery, connectivity, and traffic monitoring. With Service Connect, your applications can utilize short names and standard ports to connect to ECS services within the same cluster, across different clusters, and even across VPCs within the same AWS Region. 

Alternative options for configuring inter-service communication within Amazon ECS Services include:

-   Internal Load Balancer (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-connecting-services.html#networking-connecting-services-elb)
-   Service Discovery (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-connecting-services.html#networking-connecting-services-direct)
-   Amazon VPC Lattice (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-vpc-lattice.html)

<!-- Directory -->
On the command line, move into the lab directory; cd into 3-networking

<!-- Enabling Service Connect -->
In this section, we'll enable ECS Service Connect in our cluster by deploying two additional microservices that the UI service will communicate with:

<!-- Deploy the Assets service -->
Create an ECS task definition for the Assets service.

<!-- Push image to ecr -->

1. Create an ECR image using the AWS console named: retail-store-sample-assets

2a. I pull down the UI image from AWS and pushed it to an ECR repo in my account I created  using the following commands using the ca-central-region:

    -$ export AWS_REGION="us-east-1"

    -$ docker pull public.ecr.aws/aws-containers/retail-store-sample-assets:0.7.0

    -$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-assets

    -$ docker tag public.ecr.aws/aws-containers/retail-store-sample-assets:0.7.0  066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-assets

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-assets:latest

2b. Use the same ECS Execution (ecs-execution-role) and ECS Task role (ecs-task-role) created in the Fundamental section

3a. Create a nw task definition with the two commands below:

-$ export AWS_REGION="us-east-1"

-$ export UI_SG_ID="sg-0f1ea858b0b0b5478"

-$ export PRIVATE_SUBNET1="subnet-0966d0570f9f4ba4b"

-$ export PRIVATE_SUBNET2="subnet-0343eaef6ad4d3d19"

-$ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-asset-taskdef.json 

No need  to create the specific log group named, "retail-store-ecs-tasks", because we did in the Fundamental section

# NB "options" in task definition under "containerDefinitions" => "logConfiguration" =>

The configuration options to send to the log driver.

The options you can specify depend on the log driver. Some of the options you can specify when you use the awslogs log driver to route logs to Amazon CloudWatch include the following:

- awslogs-create-group
- Required: No

Specify whether you want the log group to be created automatically. If this option isn't specified, it defaults to false 

# Note
Your IAM policy must include the logs:CreateLogGroup permission before you attempt to use awslogs-create-group .

# 
<!-- Creating an AWS Cloud Map namespace to group application services -->

Now create a service namespace to be used by the ui, assets, and catalog services (https://docs.aws.amazon.com/cloud-map/latest/dg/creating-namespaces.html)

-$ MY_VPC="vpc-08b0317de67c51e8a"

To create a ECS namespace, run: aws servicediscovery create-private-dns-namespace --name name-of-namespace --vpc your-chosen-vpc-id

In our case to create the "retailstore.local" namesapce that will be used in creating the asset service, run:

-$ aws servicediscovery create-private-dns-namespace --name retailstore.local --vpc $MY_VPC

Similarly, to delete a namespace run: aws servicediscovery delete-namespace --id the-id-of-the-namespace

<!-- Create the corresponding Assets ECS service: -->

-$ aws ecs create-service \
    --cluster retail-store-ecs-cluster \
    --service-name assets \
    --task-definition retail-store-ecs-assets \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1}, ${PRIVATE_SUBNET2}], securityGroups=[$UI_SG_ID],assignPublicIp=DISABLED}" \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "retailstore.local",
        "services": [
            {
                "portName": "application",
                "discoveryName": "assets",
                "clientAliases": [
                    {
                        "port": 80,
                        "dnsName": "assets"
                    }
                ]
            }
        ]
    }'

Note that when we create this service, we specify --service-connect-configuration, which:

- Enables Service Connect

- Specifies a namespace that all the services will share

- Configures the Service Connect services that will be provided by this ECS service, including its alias and port number  

Read more about the flag here (https://docs.aws.amazon.com/cli/latest/reference/ecs/create-service.html) in addition to the excepts below:

# namespace -> (string)
The namespace name or full Amazon Resource Name (ARN) of the Cloud Map namespace for use with Service Connect. The namespace must be in the same Amazon Web Services Region as the Amazon ECS service and cluster. The type of namespace doesn't affect Service Connect. For more information about Cloud Map, see Working with Services in the Cloud Map Developer Guide

# portName -> (string)
The portName must match the name ("name": "application") of one of the portMappings from all the containers in the task definition of this Amazon ECS service.


<!-- # MOVE TO README-2.MD TO CONTINUE TO READ ABOUT STEPS/INSTRUCTIONS -->

  