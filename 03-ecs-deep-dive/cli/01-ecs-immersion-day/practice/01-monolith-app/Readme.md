<!-- Link: https://aws.amazon.com/tutorials/break-monolith-app-microservices-ecs-docker-ec2/ -->
# See the docs!
In this practical exercise, I will deploy a monolith (User, Post, and Thread) application to ECS 

<!-- VPC -->
All the resources here are created, where applicable, in my custom VPC deployed using the cloudformation and the template in aws-ecs-workshps/vpc.yaml. 

<!-- Repository -->
Clone the repo and delete the .git file: https://github.com/awslabs/amazon-ecs-nodejs-microservices.git


<!-- Create and Push image to ECR -->

1. Create an ECR repository named: ecs-nodejs-monolith

1b. Create an image called ecs-nodejs-monolith using the dockerfile in the root of clone repo directory by running:

    -$ cd amazon-ecs-nodejs-microservices/2-containerized/services/api (contains the  dockerfile to build the monolith)

    -$ docker build -t ecs-nodejs-monolith .

    -$ docker image ls (shows your new created image and other avalaible to you locally)

    -$ export AWS_REGION="us-east-1"

    -$ aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-monolith

    -$ docker tag ecs-nodejs-monolith:latest  066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-monolith:latest

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-monolith:latest

1b. We are going to us some of the resources created at the beginning of the workshop (checkout the 1-ecs-immersion-day-fundamentals Readme.md to see the various configurations of this resources):

    - ecs-execution-role (ECS executions role)

    - ecs-task-role (ECS task role)

    - ws-ecs-alb (ECS Load balancer. Add a listner rule to it to listen on port 3000 only from 'ecs-sg')

    - ws-ecs-tg (Load balancer target group)

    - ecs-sg (ECS security group that allows traffic only from the ECS alb)

    - ec2+alb-sg (Load balancer security group. Add an inbound rule to allow traffic on prt 3000 from ecs-sg)

<!-- ECS Cluster -->

2a.On the command line, move into the lab directory; 

-$ cd 01-monolith-app


2b.  Using the VS Code terminal, create an Amazon ECS Cluster named ecs-monolith-microservices-cluster with CloudWatch Container Insights  enabled.
    Container Insights collects, aggregates, and summarizes metrics and logs from your containerized applications and microservices:
        
    -$ export AWS_REGION="us-east-1"

    -$ aws ecs create-cluster --cluster-name ecs-monolith-microservices-cluster --region $AWS_REGION --settings name=containerInsights,value=enabled

    You received an output like below:
    {
        "cluster": {
            "clusterArn": "arn:aws:ecs:us-west-2:111111111111:cluster/ecs-monolith-microservices-cluster",
            "clusterName": "retail-store-ecs-cluster",
            "status": "ACTIVE",
            "registeredContainerInstancesCount": 0,
            "runningTasksCount": 0,
            "pendingTasksCount": 0,
            "activeServicesCount": 0,
            "statistics": [],
            "tags": [],
            "settings": [
                {
                    "name": "containerInsights",
                    "value": "enabled"
                }
            ],
            "capacityProviders": [],
            "defaultCapacityProviderStrategy": []
        }
    }

<!-- Task definitions -->
A task definition is a blueprint that describes how a container (or containers) should run on Amazon ECS. It includes various configurations such as the container image to use, the required CPU and memory, the ports to open, and the environment variables needed.

1. Let's create the task definition to be used for the UI Service using retail-store-ecs-ui-taskdef.json. Make sure that the roles and ecr image url has been pre-created using the console

    -$ aws ecs register-task-definition --cli-input-json file://ecs-monolith-taskdef.json --region $AWS_REGION

2. You can retrieve the task definition using the AWS CLI:

    -$ aws ecs describe-task-definition --task-definition ecs-nodejs-monolith

This command will display the full details of the task definition you just created.

<!-- Services -->

An ECS service enables you to run and maintain a specified number of instances of a task definition simultaneously in an Amazon ECS cluster. If any of these tasks fail or stop for any reason, the ECS service scheduler launches another instance of your task definition to replace it, maintaining the desired number of tasks in the service. This ensures high availability for your application.

ECS services are used to manage long-running applications, microservices, or other software components that require high availability. Services in ECS can be integrated with Elastic Load Balancing (ELB) to distribute traffic evenly across the tasks in the service, providing a seamless way to deploy, manage, and scale your containerized applications. Let's create the ECS service (where UI_SG_ID is the SG ID of 'ecs-sg', and PRIVATE_SUBNET1 and PRIVATE_SUBNET2 are private subnets in my account in  us-east-1 region, all taken from the console ):

-$ export AWS_REGION="us-east-1"

-$ export UI_SG_ID="sg-0f1ea858b0b0b5478"

-$ export PRIVATE_SUBNET1="subnet-0966d0570f9f4ba4b"

-$ export PRIVATE_SUBNET2="subnet-0343eaef6ad4d3d19"

-$ export UI_TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names ws-ecs-tg --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text)

-$ aws ecs create-service \
    --cluster ecs-monolith-microservices-cluster \
    --service-name ecs-nodejs-monolith \
    --task-definition ecs-nodejs-monolith \
    --desired-count 1 \
    --launch-type FARGATE \
    --load-balancers targetGroupArn=${UI_TARGET_GROUP_ARN},containerName=application,containerPort=3000 \
 --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1},${PRIVATE_SUBNET2}],securityGroups=[${UI_SG_ID}],assignPublicIp=DISABLED}"


It may take several minutes for ECS to deploy the service and for it to register as stable. While this is happening, you can explore the service in the ECS console:

You can also wait for the service to stabilize with the AWS CLI (~ 2 min):

-$ aws ecs wait services-stable --cluster ecs-monolith-microservices-cluster --services ecs-nodejs-monolith

Once the service is stable, you can view the running tasks from the CLI:

-$ aws ecs describe-tasks \
    --cluster ecs-monolith-microservices-cluster \
    --tasks $(aws ecs list-tasks --cluster ecs-monolith-microservices-cluster --query 'taskArns[]' --output text) \
    --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table

You can retrieve the load balancer URL like so:

-$ export ALB=$(aws elbv2 describe-load-balancers --name  ws-ecs-alb --query 'LoadBalancers[0].DNSName' --output text)

-$ echo http://${ALB} ; echo

<!-- Browser -->
On your broswer go to the various endpoints to results

-$ http://${ALB}

-$ http://${ALB}/api

-$ http://${ALB}/api/users

-$ http://${ALB}/api/posts

-$ http://${ALB}/api/threads


<!-- Conclusion -->

Your deployed the application successfully as a monolith! Hurray!!!!!!!!

