<!-- Link: https://aws.amazon.com/tutorials/break-monolith-app-microservices-ecs-docker-ec2/ -->
# See the docs!
In this practical exercise, I will deploy each of the User, Post, and Thread parts  application to ECS as a microservice

<!-- Repository -->
Clone the repo and delete the .git file: https://github.com/awslabs/amazon-ecs-nodejs-microservices.git


<!-- Create ECR repos -->

Create an 3 ECR repository named: 
     
    - ecs-nodejs-microservices-post
    
    - ecs-nodejs-microservices-threads

    - ecs-nodejs-microservices-users

<!-- Create docker images -->

1a.
    -$ cd amazon-ecs-nodejs-microservices/3-microservices/services/post (contains the  dockerfile to build the post application alone)

    -$ docker build -t ecs-nodejs-microservices-posts .

    -$ docker image ls (shows your new created image and other avalaible to you locally)

1b.
    -$ cd amazon-ecs-nodejs-microservices/3-microservices/services/thread (contains the  dockerfile to build the thread application alone)

    -$ docker built -t ecs-nodejs-microservices-threads .

    -$ docker image ls (shows your new created image and other avalaible to you locally)

1c.
    -$ cd amazon-ecs-nodejs-microservices/3-microservices/services/users (contains the  dockerfile to build the users application alone)

    -$ docker built -t ecs-nodejs-microservices-users .

    -$ docker image ls (shows your new created image and other avalaible to you locally)

<!-- Push images to ECR --> 

1b. Create an image called ecs-nodejs-monolith using the dockerfile in the root of clone repo directory by running:


    -$ export AWS_REGION="us-east-1"

    -$ aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 066638479762.dkr.ecr.us-east-1.amazonaws.com

    -$ docker tag ecs-nodejs-microservices-users:latest  066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-users:latest

    -$ docker tag ecs-nodejs-microservices-posts:latest  066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-posts:latest

    -$ docker tag ecs-nodejs-microservices-threads:latest  066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-thread:latest

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-users:latest

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-posts:latest

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/ecs-nodejs-microservices-threads:latest

<!-- Existing resources -->
We are going to us some of the resources created at the beginning of the workshop (checkout the 1-ecs-immersion-day-fundamentals Readme.md to see the various configurations of this resources):

    - ecs-execution-role (ECS executions role)

    - ecs-task-role (ECS task role)

    - ws-ecs-alb (ECS Load balancer. Add a listner rule to it to listen on port 3000)

    - ws-ecs-tg (Load balancer target group)

    - ecs-sg (ECS security group that allows traffic only from the ECS alb)

    - ec2+alb-sg (Load balancer security group. Add an inbound rule to allow traffic on prt 3000 from ecs-sg)

<!-- Create ALB target group  for each microservice -->
Create the following 3 target groups like ALB TG (ws-ecs-tg) of type IP addresses, that is your created VPC, IP address type IPV4, Protocol port 80, protocol HTTP, Healthcheck enabled, and HealthPath '/' amongst other defaults configurations. Name them:

    - post-tg

    - threads-tg

    - users-tg

<!-- Add new target groups to existing ALB (ws-ecs-alb) -->
Go to existing ALB on the console and add rules to forward traffice to the microservices target group depending on the route

    - Go to the EC2 console and click on Load balances

    - Click on the 'ws-ecs-alb' ALB

    - Under Listner and Rules, check the listner Https:80 
    (or https:443 if using a certificate for secure connections. You add the rule to either of this listner because that is what a typical client uses when connecting to an endpoint)

    - Click on manage rules at the top rhs of the card

    - Click Add rule and under Name and tags give the rule the name: users, click next

    - Click Add a condition 

    - From the dialog box dropdown select Path (other options include: Https method, IP Source address, Https header, and Query string )

    - In the Path, enter /api/users* and click next

    - Select Forward to groups if not already selected

    - Under target groups select the users-tg from the dropdown and click next

    - Under Listner rules and for the users rule, enter priority of 1 (can be between 1-50000) and click next

    - Review and Create

Repeat all the above to create a Rule for /api/posts/* and /api/threads/* that forwards traffic to posts-tg and threads-tg respectively

Afterall, you should have four rules: /api/users*, /api/posts*,  /api/threads*, default.

The default rule is used (traffic sent to it) when no API request matches any of: /api/users*, /api/posts*, and /api/threads*

<!-- Creating an AWS Cloud Map namespace to group application services -->

Now create a service namespace to be used by the ui, assets, and catalog services (https://docs.aws.amazon.com/cloud-map/latest/dg/creating-namespaces.html)

    -$ MY_VPC="vpc-08b0317de67c51e8a"

To create a ECS namespace, run: aws servicediscovery create-private-dns-namespace --name name-of-namespace --vpc your-chosen-vpc-id

In our case to create the "ecs-nodejs-microservices.local" namesapce that will be used in creating the asset service, run:

-$ aws servicediscovery create-private-dns-namespace --name ecs-nodejs-microservices.local --vpc $MY_VPC

Similarly, to delete a namespace run: aws servicediscovery delete-namespace --id the-id-of-the-namespace

<!-- Set Envs -->
ECS services are used to manage long-running applications, microservices, or other software components that require high availability. Services in ECS can be integrated with Elastic Load Balancing (ELB) to distribute traffic evenly across the tasks in the service, providing a seamless way to deploy, manage, and scale your containerized applications. Let's create the ECS service (where ECS_SG_ID is the SG ID of 'ecs-sg', and PRIVATE_SUBNET1 and PRIVATE_SUBNET2 are private subnets in my account in  us-east-1 region in my custom VPC, and USERS_TARGET_GROUP_ARN and POSTS_TARGET_GROUP_ARN and THREADS_TARGET_GROUP_ARN are all arns of users-tg, posts-tg, and threads-tg respectively. All taken from the console ):

-$ export AWS_REGION="us-east-1"

-$ export ECS_SG_ID="sg-0f1ea858b0b0b5478"

-$ export PRIVATE_SUBNET1="subnet-0966d0570f9f4ba4b"

-$ export PRIVATE_SUBNET2="subnet-0343eaef6ad4d3d19"

-$ USERS_TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:066638479762:targetgroup/users-tg/d632e10ef187ea94"

-$ POSTS_TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:066638479762:targetgroup/post-tg/e950f10e96c2fa7f"

-$ THREADS_TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:066638479762:targetgroup/threads-tg/244a91dbf7a6b70e"

<!-- Create ECS taskdefinitions or Users, Threads, and Posts tasks -->
On the command line, move into the lab directory; 

    -$ cd 02-monolith-app

    -$ aws ecs register-task-definition --cli-input-json file://ecs-users-taskdef.json --region $AWS_REGION

    -$ aws ecs register-task-definition --cli-input-json file://ecs-posts-taskdef.json --region $AWS_REGION

    -$ aws ecs register-task-definition --cli-input-json file://ecs-threads-taskdef.json --region $AWS_REGION

<!-- ECS Cluster -->
Using the VS Code terminal, create an Amazon ECS Cluster named ecs-monolith-microservices-cluster with CloudWatch Container Insights  enabled.
Container Insights collects, aggregates, and summarizes metrics and logs from your containerized applications and microservices:


    -$ aws ecs create-cluster --cluster-name ecs_microservices_cluster --service-connect-defaults namespace=ecs_microservices_cluster --region $AWS_REGION --settings name=containerInsights,value=enabled

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

<!-- NOTE ABOUT SERVICE CONNECT -->
I added ECS service connect to the microservices using the below part to show how ECS service connect works (container to container communication and networking)

If you don't want, just create the service/s without the below part as part of the command/iac to create the service/s:

    --service-connect-configuration '{
            "enabled": true,
            "namespace": "ecs-nodejs-microservices.local",
            "services": [
                {
                    "portName": "application",
                    "discoveryName": "users",
                    "clientAliases": [
                        {
                            "port": 3000,
                            "dnsName": "users"
                        }
                    ]
                }
            ]
        }'

<!-- Create ECS Service with Service connects for Users -->

-$ aws ecs create-service \
    --cluster ecs_microservices_cluster \
    --service-name ecs-nodejs-users \
    --task-definition ecs-nodejs-users \
    --desired-count 1 \
    --launch-type FARGATE \
    --load-balancers targetGroupArn=${USERS_TARGET_GROUP_ARN},containerName=application,containerPort=3000 \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1}, ${PRIVATE_SUBNET2}], securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "ecs_microservices_cluster",
        "services": [
            {
                "portName": "application",
                "discoveryName": "users",
                "clientAliases": [
                    {
                        "port": 3000,
                        "dnsName": "users"
                    }
                ]
            }
        ]
    }'


# namespace -> (string)
The namespace name or full Amazon Resource Name (ARN) of the Cloud Map namespace for use with Service Connect. The namespace must be in the same Amazon Web Services Region as the Amazon ECS service and cluster. The type of namespace doesn't affect Service Connect. For more information about Cloud Map, see Working with Services in the Cloud Map Developer Guide

# portName -> (string)
The portName must match the name ("name": "application") of one of the portMappings from all the containers in the task definition of this Amazon ECS service.
It may take several minutes for ECS to deploy the service and for it to register as stable. While this is happening, you can explore the service in the ECS console:

You can also wait for the service to stabilize with the AWS CLI (~ 2 min):

-$ aws ecs wait services-stable --cluster ecs-monolith-microservices-cluster --services ecs-nodejs-monolith

You can retrieve the load balancer URL like so:

-$ export ALB=$(aws elbv2 describe-load-balancers --name  ws-ecs-alb --query 'LoadBalancers[0].DNSName' --output text)

-$ echo http://${ALB} ; echo

Copy and paste the value of $ALB in your browser to see your running application and confirm it is running

-$ http://${ALB}

-$ http://${ALB}/api

-$ http://${ALB}/api/users


<!-- Scaled down the monolith aaplication and test the User microservice-->

Wait for your new users service is up and running with it's task. Then in the cluster ecs-monolith-microservices-cluster (used in this lab but created in 01-monolith-app), temporarily scaled down the number of task in the service ecs-nodejs-monolith (created in 01-monolith-app) to zero.
This is to ensure that the monolith is no longer serveing any request. Once the service is scaled down to zero, do the below again:

-$ http://${ALB}

-$ http://${ALB}/api

-$ http://${ALB}/api/users


You should still be able to get result for calls made to retrieve user data. The below will not work because we are yet to deploy their respective services:

-$ http://${ALB}/api/posts

-$ http://${ALB}/api/threads

<!-- Create ECS Service with Service connects for Users, Threads, and Posts Services -->

# 1. Deploy the Posts service

-$ aws ecs create-service \
    --cluster ecs_microservices_cluster \
    --service-name ecs-nodejs-posts \
    --task-definition ecs-nodejs-posts \
    --desired-count 1 \
    --launch-type FARGATE \
    --load-balancers targetGroupArn=${POSTS_TARGET_GROUP_ARN},containerName=application,containerPort=3000 \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1}, ${PRIVATE_SUBNET2}], securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "ecs_microservices_cluster",
        "services": [
            {
                "portName": "application",
                "discoveryName": "posts",
                "clientAliases": [
                    {
                        "port": 3000,
                        "dnsName": "posts"
                    }
                ]
            }
        ]
    }'

# 2. Deploy the Threads service

-$ aws ecs create-service \
    --cluster ecs_microservices_cluster \
    --service-name ecs-nodejs-threads \
    --task-definition ecs-nodejs-threads \
    --desired-count 1 \
    --launch-type FARGATE \
    --load-balancers targetGroupArn=${THREADS_TARGET_GROUP_ARN},containerName=application,containerPort=3000 \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1}, ${PRIVATE_SUBNET2}], securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "ecs_microservices_cluster",
        "services": [
            {
                "portName": "application",
                "discoveryName": "threads",
                "clientAliases": [
                    {
                        "port": 3000,
                        "dnsName": "threads"
                    }
                ]
            }
        ]
    }'


When you visit the post and threads endopoints below, the posts and threads data are returned:

-$ http://${ALB}/api/posts

-$ http://${ALB}/api/threads

At this point the microservices are reachable and returns there individual data. 

***CONGRATULATION ON SUCCESSFULLY DEPLOYING YOUR FIRST MICROSERVICES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!***

Feel free to delete the monolith service at this point because you no longer need it.

<!-- Enable ECS Exec -->

In this section, you'll enable the ECS Exec feature to run commands in or get a shell to a container running on an EC2 instance or Fargate. Enabling ECS Exec is beneficial for operational management and advantageous from a security perspective. It offers controlled access to containers running in your ECS tasks, allowing for secure, audited, and interactive troubleshooting without having to SSH into hosts.

By leveraging IAM policies and roles, you can tightly control who has access to execute commands within containers, thus enhancing the overall security posture. Additionally, all commands executed through ECS Exec are logged in CloudWatch, providing an audit trail for compliance and monitoring purposes. More information can be found here => https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html.

***Set the IAM role for the user***
Since you'll be using ECS Exec from your IDE, ensure that the IAM role attached to the IDE has the necessary IAM policies. Update the IAM role associated with the EC2 instance running your IDE by adding the following in-line policy, where 'ecs-monolith-microservices-cluster' is the cluster where we have our microservices:

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
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:task/ecs-monolith-microservices-cluster/*",
                    "arn:aws:ecs:${AWS_REGION}:${ACCOUNT_ID}:cluster/*"
                ]
            }
        ]
    }
    EOF

***Now attach the policy (the above and below command not applicable to me since my IDE is configure with admin access):***

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

Verify you have AWS Session Manger installed by running on Linux (if installed should return: The Session Manager plugin is installed successfully. Use the AWS CLI to start a session.): 

-$ session-manager-plugin

Other follow instruction here to install AWS Session-Manager plugin and verify installation as above

    ***https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html (Ubuntu Linux)***

    ***https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html (Other systems)***

<!-- Enable Amazon ECS Exec on services and tasks -->
Update the users, posts and threads services to enable Amazon ECS Exec using the --enable-execute-command flag:

-$ aws ecs update-service \
    --cluster ecs_microservices_cluster \
    --service ecs-nodejs-users \
    --task-definition ecs-nodejs-users \
    --enable-execute-command \
    --force-new-deployment

-$ aws ecs update-service \
    --cluster ecs_microservices_cluster \
    --service ecs-nodejs-posts \
    --task-definition ecs-nodejs-posts \
    --enable-execute-command \
    --force-new-deployment

-$ aws ecs update-service \
    --cluster ecs_microservices_cluster \
    --service ecs-nodejs-threads \
    --task-definition ecs-nodejs-threads \
    --enable-execute-command \
    --force-new-deployment


Wait for all ECS to deploy the changes to the service (~ 5 min)

<!-- Get each task from each service -->

Run the following command to select one of the running tasks in ecs-nodejs-threads, ecs-nodejs-posts, and ecs-nodejs-users with enableExecuteCommand enabled:

-$ ECS_USERS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster ecs-monolith-microservices-cluster \
    --service-name ecs-nodejs-users --query 'taskArns[]' --output text | \
    xargs -n1 aws ecs describe-tasks --cluster ecs-monolith-microservices-cluster --tasks | \
    jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
    head -n 1)


-$ ECS_POSTS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster ecs-monolith-microservices-cluster \
    --service-name ecs-nodejs-posts --query 'taskArns[]' --output text | \
    xargs -n1 aws ecs describe-tasks --cluster ecs-monolith-microservices-cluster --tasks | \
    jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
    head -n 1)


-$ ECS_THREADS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster ecs-monolith-microservices-cluster \
    --service-name ecs-nodejs-threads --query 'taskArns[]' --output text | \
    xargs -n1 aws ecs describe-tasks --cluster ecs-monolith-microservices-cluster --tasks | \
    jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
    head -n 1)

Print and checkout that the task arns match what you have on the console.

-$ echo $ECS_USERS_EXEC_TASK_ARN

-$ echo $ECS_POSTS_EXEC_TASK_ARN

-$ echo $ECS_THREADS_EXEC_TASK_ARN



<!-- Connect to the ECS Users Task container and call the Threads and Posts microservices on the same service connect namespace  -->

***NOTE THAT THE SHELL FOR THE 'mhart/alpine-node:7.10.1' FOR BUUILDING THE IMAGES IS: /bin/ash AND THE PACKAGE MANAGER IS 'apk'***

Start your /bin/ash interactive session in the running task:

-$ if [ -z ${ECS_USERS_EXEC_TASK_ARN} ]; then echo "ECS_USERS_EXEC_TASK_ARN is not correctly configured!"; else
    aws ecs execute-command --cluster ecs-monolith-microservices-cluster \
    --task $ECS_USERS_EXEC_TASK_ARN \
    --container application \
    --interactive \
    --command "/bin/ash"
fi

You should see output like this:

    The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

    Starting session with SessionId: ecs-execute-command-vvdysulqbcz2txr2d262sw2s64

    /srv
    
    /srv cat /etc/hosts

Outputs something similar like below:

127.0.0.1 localhost
10.0.3.236 ip-10-0-3-236.ec2.internal
127.255.0.1 posts
2600:f0f0:0:0:0:0:0:1 posts
127.255.0.2 threads
2600:f0f0:0:0:0:0:0:2 threads
127.255.0.3 users
2600:f0f0:0:0:0:0:0:3 users
    
    /srv#

    /srv# apk update
    
    /srv# apk add jq 
    
    /srv# apk add curl   
    
    /srv# apk upgrade libressl
    
    /srv# curl http://posts:3000/api/posts | jq
    
    /srv# curl http://threads:3000/api/threads | jq

To terminate your session:

    /srv exit 

<!-- #Connect to the ECS Posts Task container and call other microservices on the same service connect namespace    -->
Start your /bin/ash interactive session in the running task:

-$ if [ -z ${ECS_POSTS_EXEC_TASK_ARN} ]; then echo "ECS_POSTS_EXEC_TASK_ARN is not correctly configured!"; else
aws ecs execute-command --cluster ecs-monolith-microservices-cluster \
    --task $ECS_POSTS_EXEC_TASK_ARN \
    --container application \
    --interactive \
    --command "/bin/ash"
fi

You should see output like this:

    The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

    Starting session with SessionId: ecs-execute-command-vvdysulqbcz2txr2d262sw2s64
    
    /srv
    
    /srv cat /etc/hosts

Outputs something similar like below:

    127.0.0.1 localhost
    10.0.3.236 ip-10-0-3-236.ec2.internal
    127.255.0.1 posts
    2600:f0f0:0:0:0:0:0:1 posts
    127.255.0.2 threads
    2600:f0f0:0:0:0:0:0:2 threads
    127.255.0.3 users
    2600:f0f0:0:0:0:0:0:3 users

    /srv# apk update
    
    /srv# apk add jq 
    
    /srv# apk add curl   
    
    /srv# apk upgrade libressl
    
    /srv# curl http://users:3000/api/users | jq
    
    /srv# curl http://threads:3000/api/threads | jq

To terminate your session:

    /srv exit    

<!-- #Connect to the ECS Threads Task container and call other microservices on the same service connect namespace    -->


Start your /bin/ash interactive session in the running task:

-$ if [ -z ${ECS_THREADS_EXEC_TASK_ARN} ]; then echo "ECS_THREADS_EXEC_TASK_ARN is not correctly configured!"; else
aws ecs execute-command --cluster ecs-monolith-microservices-cluster \
    --task $ECS_THREADS_EXEC_TASK_ARN \
    --container application \
    --interactive \
    --command "/bin/ash"
fi

You should see output like this:

    The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

    Starting session with SessionId: ecs-execute-command-vvdysulqbcz2txr2d262sw2s64

    
    /srv
    
    /srv cat /etc/hosts

Outputs something similar like below:

    127.0.0.1 localhost
    10.0.3.236 ip-10-0-3-236.ec2.internal
    127.255.0.1 posts
    2600:f0f0:0:0:0:0:0:1 posts
    127.255.0.2 threads
    2600:f0f0:0:0:0:0:0:2 threads
    127.255.0.3 users
    2600:f0f0:0:0:0:0:0:3 users

    /srv# apk update
    
    /srv# apk add jq 
    
    /srv# apk add curl   
    
    /srv# apk upgrade libressl
    
    /srv# curl http://users:3000/api/users | jq
    
    /srv# curl http://posts:3000/api/posts | jq

To terminate your session:

    /srv exit   

<!-- My command notes -->
aws ecs execute-command --cluster ecs-monolith-microservices-cluster --task arn:aws:ecs:us-east-1:066638479762:task/ecs-monolith-microservices-cluster/0f3d429fc50d466d8a752870b273d729 --container application --interactive --command "/bin/ash"

aws ecs execute-command --cluster nginx_cluster --task arn:aws:ecs:us-east-1:066638479762:task/nginx_cluster/24bc2094635f4dbabb82549e3fcdffb2 --container nginx --interactive --command "/bin/bash"

