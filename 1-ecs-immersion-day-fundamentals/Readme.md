<!-- Region -->
All lab resources was created in us-east-1
<!-- ECR Images -->
These lab uses images already pushed to aws Public ECR repo

<!-- https://github.com/aws-containers/retail-store-sample-app/blob/main/README.md -->
# Please read the README.md file (using Github bcs the md file is well formatted and links shows as link and not so VS Code) in 'zz-retail-store-sample-app/README.md' folder to get info about the app and links to various images including the UI image I used in this workshop for demonstration purposes

<!-- Push image to ecr -->

1. Create an ECR image using the AWS console named: retail-store-sample-ui

2a. I pull down the UI image from AWS and pushed it to an ECR repo in my account I created  using the following commands using the ca-central-region:

    -$ export AWS_REGION="us-east-1"

    -$ docker pull public.ecr.aws/aws-containers/retail-store-sample-ui:0.7.0

    -$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-ui

    -$ docker tag public.ecr.aws/aws-containers/retail-store-sample-ui:0.7.0  066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-ui

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-ui:latest

2b. Using the AWS console create an ecs execution role (ecs-execution-role) with AWS managed permissions of AmazonAPIGatewayPushToCloudWatchLogs, SecretsManagerReadWrite, AmazonSSMReadOnlyAccess, and AmazonECSTaskExecutionRolePolicy. Add, if not already there, a trust relationship with the following servics - "ssm.amazonaws.com", "secretsmanager.amazonaws.com", "cloudformation.amazonaws.com", "ecs-tasks.amazonaws.com", and "ecs.amazonaws.com". Cloudformation is for when I use cloudformation to update cluster, service, and task using codepipeline cloudformation deploy action.

2c. Using the AWS console create an ecs task role (ecs-task-role)  with AWS managed permissions of AmazonAPIGatewayPushToCloudWatchLogs, SecretsManagerReadWrite, AmazonSSMReadOnlyAccess, and AmazonECSTaskExecutionRolePolicy. Add, if not already there, a trust relationship with the following servics - ssm.amazonaws.com, "secretsmanager.amazonaws.com", "ecs-tasks.amazonaws.com", and "ecs.amazonaws.com".


3a. Deploy a new VPC using the cloudformationn and the template in aws-ecs-workshps/vpc.yaml. Proceed to the next step as the VPC resources are provisioning

<!-- Directory -->
On the command line, move into the lab directory; cd into 1-ecs-immersion-day-fundamentals


3b.  Using the VS Code terminal, create an Amazon ECS Cluster named retail-store-ecs-cluster with CloudWatch Container Insights  enabled.
    Container Insights collects, aggregates, and summarizes metrics and logs from your containerized applications and microservices:
        
    -$ export AWS_REGION="us-east-1"

    -$ aws ecs create-cluster --cluster-name retail-store-ecs-cluster --region $AWS_REGION --settings name=containerInsights,value=enabled

    You received an output like below:
    {
        "cluster": {
            "clusterArn": "arn:aws:ecs:us-west-2:111111111111:cluster/retail-store-ecs-cluster",
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

    -$ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-ui-taskdef.json --region $AWS_REGION

# NB "options" in task definition under "containerDefinitions" => "logConfiguration" =>

The configuration options to send to the log driver.

The options you can specify depend on the log driver. Some of the options you can specify when you use the awslogs log driver to route logs to Amazon CloudWatch include the following:

- awslogs-create-group
- Required: No

Specify whether you want the log group to be created automatically. If this option isn't specified, it defaults to false 

# Note
Your IAM policy must include the logs:CreateLogGroup permission before you attempt to use awslogs-create-group .

#     

Now create the a log group with the specific named, "retail-store-ecs-tasks" , which is used in the task definition using the console or cli as below. Otherwise there CW related error

    -$ aws logs create-log-group --log-group-name retail-store-ecs-tasks

2. You can retrieve the task definition using the AWS CLI:

    -$ aws ecs describe-task-definition --task-definition retail-store-ecs-ui

This command will display the full details of the task definition you just created.

<!-- Load Balancer and Target Group -->

1a. Using the AWS console create an ALB SG (named: ec2+alb-sg) that allows inbound traffic on port 80, 22, 443, from the your IP and allows all outbound traffic

1b. Using the AWS console create an ECS Service SG (ecs-sg) that allows inbound traffic from ALB SG and allows all outbound traffic

1. Using the AWS console add an inbound rule to th SG in  step 1a (ec2+alb-sg) that allows inbound traffic on port 8080 from thee ECS SG (ecs-sg)

2. Using the AWS console Create an ALB TG (ws-ecs-tg) of type IP addresses, that is your created VPC, IP address type IPV4, Protocol port 8080, protocol HTTP, Healthcheck enabled, and HealthPath '/' amongst other defaults configurations

3. Using the AWS console create an ALB (ws-ecs-alb) that is internet facing, in your created VPC with 2 private subnets in your created VPC, uses the SG in step 1a above, of type Application with listner rules associated with this ALB that forward to the TG (ws-ecs-tg) on port 8080 and 80

<!-- Services -->

An ECS service enables you to run and maintain a specified number of instances of a task definition simultaneously in an Amazon ECS cluster. If any of these tasks fail or stop for any reason, the ECS service scheduler launches another instance of your task definition to replace it, maintaining the desired number of tasks in the service. This ensures high availability for your application.

ECS services are used to manage long-running applications, microservices, or other software components that require high availability. Services in ECS can be integrated with Elastic Load Balancing (ELB) to distribute traffic evenly across the tasks in the service, providing a seamless way to deploy, manage, and scale your containerized applications. Let's create the ECS service (where UI_SG_ID is the SG ID of 'ecs-sg', and PRIVATE_SUBNET1 and PRIVATE_SUBNET2 are private subnets in my account in  us-east-1 region, all taken from the console ):

-$ export AWS_REGION="us-east-1"

-$ export UI_SG_ID="sg-0f1ea858b0b0b5478"

-$ export PRIVATE_SUBNET1="subnet-0966d0570f9f4ba4b"

-$ export PRIVATE_SUBNET2="subnet-0343eaef6ad4d3d19"

-$ export UI_TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names ws-ecs-tg --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text)

-$ aws ecs create-service \
    --cluster retail-store-ecs-cluster \
    --service-name ui \
    --task-definition retail-store-ecs-ui \
    --desired-count 2 \
    --launch-type FARGATE \
    --load-balancers targetGroupArn=${UI_TARGET_GROUP_ARN},containerName=application,containerPort=8080 \
 --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1},${PRIVATE_SUBNET2}],securityGroups=[${UI_SG_ID}],assignPublicIp=DISABLED}"


It may take several minutes for ECS to deploy the service and for it to register as stable. While this is happening, you can explore the service in the ECS console:

You can also wait for the service to stabilize with the AWS CLI (~ 2 min):

-$ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui

Once the service is stable, you can view the running tasks from the CLI:

-$ aws ecs describe-tasks \
    --cluster retail-store-ecs-cluster \
    --tasks $(aws ecs list-tasks --cluster retail-store-ecs-cluster --query 'taskArns[]' --output text) \
    --query "tasks[*].[group, launchType, lastStatus, healthStatus, taskArn]" --output table

You can retrieve the load balancer URL like so:

-$ export RETAIL_ALB=$(aws elbv2 describe-load-balancers --name  ws-ecs-alb --query 'LoadBalancers[0].DNSName' --output text)

-$ echo http://${RETAIL_ALB} ; echo

<!-- Updating a service -->
In this section, you'll learn how to update an ECS service. This process is useful in scenarios such as changing the container image or modifying the configuration.

Environment variables are one of the primary mechanisms used to configure container workloads, regardless of the orchestrator. You'll alter the configuration of the UI service by passing a new environment variable that will alter the behavior of the workload. In this case, you'll use the RETAIL_UI_BANNER setting, which will add a banner to the page.

Environment variables are expressed in ECS task definitions with a name and a value like so which has be added  to the retail-store-ecs-ui-taskdef-update.json:

    "environment": [
        {
            "name": "RETAIL_UI_BANNER",
            "value": "We've updated the UI service!"
        }
    ]

Now, use the register-task-definition command to update the task definition:

-$ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-ui-taskdef-updated.json

It's important to note that ECS task definitions are immutable, which means they cannot be modified after creation. Instead, the above command will create a new task definition revision, which is a copy of the current task definition with the new parameter values replacing the existing ones.

You can check that you now have multiple task definition revisions with the following command:

-$ aws ecs list-task-definitions --family-prefix retail-store-ecs-ui

With output like below:

{
    "taskDefinitionArns": [
        "arn:aws:ecs:us-east-1:066638479762:task-definition/retail-store-ecs-ui:1",
        "arn:aws:ecs:us-east-1:066638479762:task-definition/retail-store-ecs-ui:2",
        ...
        ...
        ...
}

Now you need to update the ECS service to use the new task definition revision:

-$ aws ecs update-service --cluster retail-store-ecs-cluster --service ui --task-definition retail-store-ecs-ui --region $AWS_REGION

Wait for ECS to deploy the changes to the service (~ 5 min):

-$ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services ui

Now refresh your browser, and you will see the banner has been added based on your environment variables (Not in my case as I appear to be using a different app or docker image tag bcs the example was using "public.ecr.aws/aws-containers/retail-store-sample-ui:0.7.0" while I used "public.ecr.aws/aws-containers/retail-store-sample-ui:1.0.0" )

<!-- Enable ECS Exec -->
In this section, you'll enable the ECS Exec feature to run commands in or get a shell to a container running on an EC2 instance or Fargate. Enabling ECS Exec is beneficial for operational management and advantageous from a security perspective. It offers controlled access to containers running in your ECS tasks, allowing for secure, audited, and interactive troubleshooting without having to SSH into hosts.

By leveraging IAM policies and roles, you can tightly control who has access to execute commands within containers, thus enhancing the overall security posture. Additionally, all commands executed through ECS Exec are logged in CloudWatch, providing an audit trail for compliance and monitoring purposes. More information can be found here => https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html.

# Set the IAM role for the user
Since you'll be using ECS Exec from your IDE, ensure that the IAM role attached to the IDE has the necessary IAM policies. Update the IAM role associated with the EC2 instance running your IDE by adding the following in-line policy:

    cat << EOF > ecs-exec-command-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ecs:ExecuteCommand",
                    "ecs:DescribeTasks"
                ],
                "Resource": [
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:task/retail-store-ecs-cluster/*",
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:cluster/*"
                ]
            }
        ]
    }
    EOF

# Now attach the policy (the above and below command not applicable to me since my IDE is configure with admin access):

-$ aws iam put-role-policy \
    --role-name $(aws sts get-caller-identity --query 'Arn' | cut -d'/' -f2) \
    --policy-name AmazonECSExecCommand \
    --policy-document file://ecs-exec-command-policy.json

You can check the detailed information of the policy using the following command:

-$ aws iam get-role-policy \
    --role-name $(aws sts get-caller-identity --query 'Arn' | cut -d'/' -f2) \
    --policy-name AmazonECSExecCommand

The result should look like this:

{
    "RoleName": "CdkStack-IdeIdeRoleD654ADD4-az3tY63ezTJh",
    "PolicyName": "AmazonECSExecCommand",
    "PolicyDocument": {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ecs:ExecuteCommand",
                    "ecs:DescribeTasks"
                ],
                "Resource": [
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:task/retail-store-ecs-cluster/*",
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:cluster/*"
                ]
            }
        ]
    }
} 

<!-- Set the IAM role for the ECS Task Role -->
ECS Exec needs a task IAM role for SSM communication. Add the below policy inline to the task role (ecs-task-role) permissions using the console and give it the name say "retailStoreEcsExecPermission":

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "retailStoreEcsExecPermission",
                "Effect": "Allow",
                "Action": [
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel"		    
                ],
                "Resource": "*"
            }
        ]
    }

Verify you have AWS Session Manger installed by running on Linus: 

-$ session-manager-plugin

Other follow instruction here to install AWS Session-Manager plugin and verify installation as above

    https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html (Ubuntu Linux)

    https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html (Other systems)

<!-- Enable Amazon ECS Exec on the task -->
Update the UI Service to enable Amazon ECS Exec using the --enable-execute-command flag:

-$ aws ecs update-service \
    --cluster retail-store-ecs-cluster \
    --service ui \
    --task-definition retail-store-ecs-ui \
    --enable-execute-command \
    --force-new-deployment

Wait for ECS to deploy the changes to the service (~ 5 min)

Run the following command to select one of the running UI tasks with enableExecuteCommand enabled:

-$ ECS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster retail-store-ecs-cluster \
    --service-name ui --query 'taskArns[]' --output text | \
    xargs -n1 aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks | \
    jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
    head -n 1)

-$ echo $ECS_EXEC_TASK_ARN

<!-- #Connect to the ECS Task  -->
Start your /bin/bash interactive session in the running task:

-$ if [ -z ${ECS_EXEC_TASK_ARN} ]; then echo "ECS_EXEC_TASK_ARN is not correctly configured!"; else
aws ecs execute-command --cluster retail-store-ecs-cluster \
    --task $ECS_EXEC_TASK_ARN \
    --container application \
    --interactive \
    --command "/bin/bash"
fi

You should see output like this:

    The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

    Starting session with SessionId: ecs-execute-command-vvdysulqbcz2txr2d262sw2s64
    bash-5.2#

To terminate your session:

-$ exit