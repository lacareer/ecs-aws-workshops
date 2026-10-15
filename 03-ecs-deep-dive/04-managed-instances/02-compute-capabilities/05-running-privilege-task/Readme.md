<!--    Managed Instance with Privilege Mode -->

Continuation of the previous lab

<!-- ECS Managed Instance -->
To see ECS instance to indicate that the task is on a managed instance do the below because the page ui has change since the lab was recorded and the screenshot differs

- Go to ECS
- Click on the Cluster
- Click on the service and click the specific service
- Click on the task under the chosen service
- Click on a task tab
- Click on the task
- Make sure the configuration tab is selected
- Under configuration section, click on the highlighted link immediately under "Container instance ID"
- In the general configuration section you will find the 'Instance ID' with value i-xxxxx.. underneath it
- Click on the instance ID under Instance ID
- This opens a summary page of the  instance where the task is placed and it indicated amongst other that it is 'Managed'


*** Note to see images on page ***
Note that the cloudformation template does not contain a service [although it worked with a service when I tested it with the  commented service but deployed many images]

This is intentional as we only want to run the task to build the image one time or when we want.



<!-- Running Task -->
Using AWS CloudShell or you local AWS profile, Run thecommand below to run  the task that builds an image and pushed to ECR.

Make  sure to chnage the values of the variables to an existing variable from your deployment and VPC

    $ PRIVATE_SUBNET1="subnet-0726f43f460bb02b6"
    $ PRIVATE_SUBNET2="subnet-0e8ed0cdacb3a48c8"
    $ ECS_INSTANCE_SG_ID="sg-06986c6ba54a17eff"

    $ aws ecs run-task \
    --cluster retail-store-ecs-cluster \
    --task-definition retail-store-image-builder \
    --capacity-provider-strategy capacityProvider=retail-store-ecs-cluster-managed-instances-cp,weight=1 \
    --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNET1},${PRIVATE_SUBNET2}],securityGroups=[${ECS_INSTANCE_SG_ID}],assignPublicIp=DISABLED}" --no-cli-pager

The returned result should  be similar to the below:

        {
            "tasks": [
                {
                    "attachments": [],
                    "capacityProviderName": "retail-store-ecs-cluster-managed-instances-cp",
                    "clusterArn": "arn:aws:ecs:us-east-1:944103138569:cluster/retail-store-ecs-cluster",
                    "containers": [],
                    "cpu": "2048",
                    "createdAt": "2026-10-05T13:15:30.213000+00:00",
                    "desiredStatus": "RUNNING",
                    "enableExecuteCommand": false,
                    "group": "family:retail-store-image-builder",
                    "lastStatus": "PROVISIONING",
                    "launchType": "MANAGED_INSTANCES",
                    "memory": "4096",
                    "overrides": {
                        "containerOverrides": [
                            {
                                "name": "dind"
                            },
                            {
                                "name": "builder"
                            }
                        ],
                        "inferenceAcceleratorOverrides": []
                    },
                    "tags": [],
                    "taskArn": "arn:aws:ecs:us-east-1:944103138569:task/retail-store-ecs-cluster/0d2d138c63d647b68f7109d360d73bea",
                    "taskDefinitionArn": "arn:aws:ecs:us-east-1:944103138569:task-definition/retail-store-image-builder:2",
                    "version": 1
                }
            ],
            "failures": []
        }


Give it some time and look at the ECR repo to see the pushed image


