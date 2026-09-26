<!-- Deploy the Catalog service -->
Set AWS account number variable

-$ export AWS_REGION="us-east-1"
-$ export ACCOUNT_ID="066638479762"

<!-- Push image to ecr -->

1. Create an ECR image using the AWS console named: retail-store-sample-assets

2a. I pull down the UI image from AWS and pushed it to an ECR repo in my account I created  using the following commands using the ca-central-region:

    -$ export AWS_REGION="us-east-1"

    -$ docker pull public.ecr.aws/aws-containers/retail-store-sample-catalog:0.7.0

    -$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-catalog

    -$ docker tag public.ecr.aws/aws-containers/retail-store-sample-catalog:0.7.0  066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-catalog

    -$ docker push 066638479762.dkr.ecr.us-east-1.amazonaws.com/retail-store-sample-catalog:latest


Create an ECS task definition for the Catalog service using the same ECS Execution (ecs-execution-role) and ECS Task role (ecs-task-role) created in the Fundamental section.

# Note that the catalog part of this workshop interacts with a database that I did not deploy. Completing this part to see how service discovery works in ECS

-$ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-catalog-taskdef.json

Create dummy values for all secrets in the task definition above. However, the task will keep failing bcs I don't have the DB.

{
        "name": "DB_ENDPOINT",
        "valueFrom": "arn:aws:ssm:us-east-1:066638479762:parameter/retail-store-ecs/catalog/db-endpoint"
    },
    {
        "name": "DB_PASSWORD",
        "valueFrom": "arn:aws:secretsmanager:us-east-1:066638479762:secret:retail-store-ecs-catalog-db:password::"
    },
    {
        "name": "DB_USER",
        "valueFrom": "arn:aws:secretsmanager:us-east-1:066638479762:secret:retail-store-ecs-catalog-db:username::"
    }
}

- Create this secrets in parameter store /retail-store-ecs/catalog/db-endpoint
- Create these secrets, without the double colons at the end, in Secret Manager: "retail-store-ecs-catalog-db:password" and "retail-store-ecs-catalog-db:username"


<!-- Create the corresponding Catalog ECS service: -->

# I continued just for know how!!!!!!!!!!!!!!!
# If you deploy this service, the task will keep failing bcs I don't have the DB. Or set the number of task to 0 instead of 1 which I did below

-$ aws ecs create-service \
    --cluster retail-store-ecs-cluster \
    --service-name catalog \
    --task-definition retail-store-ecs-catalog \
    --desired-count 0 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1}, ${PRIVATE_SUBNET2}], securityGroups=[$UI_SG_ID],assignPublicIp=DISABLED}" \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "retailstore.local",
        "services": [
            {
                "portName": "application",
                "discoveryName": "catalog",
                "clientAliases": [
                    {
                        "port": 80,
                        "dnsName": "catalog"
                    }
                ]
            }
        ]
    }'

<!-- Updating the UI service -->
Before updating the UI service, let's wait for the new services to finish deploying (~ 2 min):    

-$ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services catalog
-$ aws ecs wait services-stable --cluster retail-store-ecs-cluster --services assets

The following environment variables need to be added to the UI task definition to link the UI service with the Catalog and Asset services:

    "environment": [
        {
            "name": "ENDPOINTS_CATALOG",
            "value": "http://catalog"
        },
        {
            "name": "ENDPOINTS_ASSETS",
            "value": "http://assets"
        }
    ]

Now deploy the change:

-$ aws ecs register-task-definition --cli-input-json file://retail-store-ecs-ui-taskdef-updated.json

Now update the UI service with the new task definition and forcing a new deployment (~ 5 min):

-$ aws ecs update-service \
    --cluster retail-store-ecs-cluster \
    --service ui \
    --task-definition retail-store-ecs-ui \
    --force-new-deployment \
    --service-connect-configuration '{
        "enabled": true,
        "namespace": "retailstore.local",
        "services": [
            {
                "portName": "application",
                "discoveryName": "ui",
                "clientAliases": [
                    {
                        "port": 80,
                        "dnsName": "ui"
                    }
                ]
            }
        ]
    }'

# The task in the force deployment will keep failing with a 303 error at the ALB target group - ws-ecs-tg
# So I change the ws-ecs-tg sucess code to 200-399
<!-- Explore Web Application -->
Since we've deployed not only the UI service but also the Assets and Catalog services, the application's appearance has slightly changed.

-$ export RETAIL_ALB=$(aws elbv2 describe-load-balancers --name ws-ecs-alb --query 'LoadBalancers[0].DNSName' --output text)

-$ echo http://${RETAIL_ALB} ; echo

Paste the URL(or the route 53 record Alias record, ui.chukky.click, I created under my hostedzone chukky.click) into a web browser to access the application.

<!-- Examining the services AND Metrics -->
# READ DOC ABOUT THIS SECTION IN THE ATTACHED DOCS BCS IT CONTAINS SCREENSHOTS OF THE INTERCONNECTIVITY BETWEEN ALL 3 SERVICES

<!-- Advanced ECS Service Connect to the ECS Task -->
Execute the following command to select one of the running tasks with enableExecuteCommand enabled:

-$ ECS_EXEC_TASK_ARN=$(aws ecs list-tasks --cluster retail-store-ecs-cluster \
    --service-name ui --query 'taskArns[]' --output text | \
    xargs -n1 aws ecs describe-tasks --cluster retail-store-ecs-cluster --tasks | \
    jq -r '.tasks[] | select(.enableExecuteCommand == true) | .taskArn' | \
    head -n 1)

echo $ECS_EXEC_TASK_ARN

This will output the ARN of the task:

-$ arn:aws:ecs:us-west-2:XXXXXXXXXX:task/retail-store-ecs-cluster/0564778486a846599b8bd6b544e5f6eb

Now, start a /bin/bash interactive session in the running task:

-$  if [ -z ${ECS_EXEC_TASK_ARN} ]; then echo "ECS_EXEC_TASK_ARN is not correctly configured!"; else
        aws ecs execute-command --cluster retail-store-ecs-cluster \
            --task $ECS_EXEC_TASK_ARN \
            --container application \
            --interactive \
            --command "/bin/bash"
    fi

<!-- Setup environment -->
In the Bash shell, install the jq command on the running container to format the JSON output on the command line:

-$ yum install jq -y

<!-- Explore the host file -->
The /etc/hosts file provides the mapping of fully qualified domain names (FQDNs) to their respective IP addresses. Review the content of the /etc/hosts file by running the following command:

-$ cat /etc/hosts

Output like so:

    127.0.0.1 localhost
    X.X.X.X ip-X-X-X-X.us-west-2.compute.internal
    127.255.0.1 assets
    2600:f0f0:0:0:0:0:0:1 assets
    127.255.0.2 catalog
    2600:f0f0:0:0:0:0:0:2 catalog
    127.255.0.3 ui
    2600:f0f0:0:0:0:0:0:3 ui

The file contains the three Discovery names set up in the ECS Namespace with three different local IPs 127.255.0.X (IPv4 and IPv6). These local IPs all point to the same ECS local proxy, which will redirect the traffic to the appropriate ECS remote proxy bound to the specific service.

<!-- Test the connection to the Catalog service -->
Test the connection to the Catalog API from the running container:

-$ curl http://catalog/catalogue/tags | jq

    [
        {
            "name": "smart",
            "displayName": "Smart"
        },
        {
            "name": "dress",
            "displayName": "Dress"
        },
        {
            "name": "luxury",
            "displayName": "Luxury"
        },
        {
            "name": "casual",
            "displayName": "Casual"
        }
    ]

To terminate your exec session, run:

-$ exit


<!-- ECS with TLS -->
# READ DOC ABOUT THIS SECTION SECTION IN THE ATTACHED DOCS BCS IT CONTAINS COMMANDS


